using System.Text.Json;

namespace JET.Bridge
{
    public static class JetBridgeScriptFactory
    {
        public static string Create(IReadOnlyCollection<string> supportedActions)
        {
            var actionsJson = JsonSerializer.Serialize(supportedActions.OrderBy(static action => action).ToArray());

            return $$"""
(function () {
    if (!window.chrome || !window.chrome.webview) {
        return;
    }

    if (window.jet) {
        return;
    }

    const supportedActions = Object.freeze({{actionsJson}});
    const pending = new Map();

    function createRequestId() {
        if (window.crypto && typeof window.crypto.randomUUID === 'function') {
            return window.crypto.randomUUID();
        }

        return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    }

    window.jet = Object.freeze({
        supportedActions,
        invoke(action, payload) {
            return new Promise((resolve, reject) => {
                const requestId = createRequestId();
                pending.set(requestId, { resolve, reject });

                window.chrome.webview.postMessage({
                    requestId,
                    action,
                    payload: payload ?? {}
                });
            });
        }
    });

    window.chrome.webview.addEventListener('message', event => {
        const message = event.data;
        if (!message || !message.requestId) {
            return;
        }

        const pendingRequest = pending.get(message.requestId);
        if (!pendingRequest) {
            return;
        }

        pending.delete(message.requestId);

        if (message.ok) {
            pendingRequest.resolve(message.data ?? null);
            return;
        }

        const errorMessage = message.error && message.error.message
            ? message.error.message
            : 'Unknown bridge error.';

        pendingRequest.reject(new Error(errorMessage));
    });

    window.addEventListener('DOMContentLoaded', async () => {
        try {
            const bootstrap = await window.jet.invoke('app.bootstrap', {});
            window.__JET_BOOTSTRAP__ = bootstrap;

            const statusBadge = document.getElementById('statusBadge');
            if (statusBadge && bootstrap && bootstrap.database && bootstrap.database.provider) {
                statusBadge.textContent = `Shell Ready / ${bootstrap.database.provider}`;
            }

            console.info('JET bootstrap', bootstrap);
        }
        catch (error) {
            console.error('JET bootstrap failed', error);
        }

        window.dispatchEvent(new CustomEvent('jet:bridge-ready', {
            detail: { supportedActions }
        }));
    }, { once: true });
})();
""";
        }
    }
}
