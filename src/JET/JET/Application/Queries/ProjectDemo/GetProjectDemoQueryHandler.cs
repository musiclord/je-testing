using JET.Application.Contracts;

namespace JET.Application.Queries.ProjectDemo
{
    public sealed class GetProjectDemoQueryHandler
    {
        public Task<DemoProjectDto> HandleAsync(GetProjectDemoQuery query, CancellationToken cancellationToken)
        {
            var result = new DemoProjectDto(
                "DEMO Manufacturing Co.",
                "製造業",
                "2024-01-01",
                "2024-12-31",
                "2024-12-25",
                "demo-gl.xlsx",
                "demo-tb.xlsx",
                "demo-account-mapping.xlsx",
                new List<Dictionary<string, object?>>
                {
                    new() { ["Document Number"] = "JE-0001", ["Line Item"] = 1, ["Post Date"] = "2024-12-31", ["Approval Date"] = "2025-01-03", ["Account Number"] = "1101", ["Account Name"] = "應收帳款", ["Description"] = "Year-end revenue adjustment", ["Source Module"] = "GL", ["Created By"] = "amy.lin", ["Approved By"] = "manager.chen", ["Manual"] = 1, ["Amount"] = 500000 },
                    new() { ["Document Number"] = "JE-0001", ["Line Item"] = 2, ["Post Date"] = "2024-12-31", ["Approval Date"] = "2025-01-03", ["Account Number"] = "4001", ["Account Name"] = "銷貨收入", ["Description"] = "Year-end revenue adjustment", ["Source Module"] = "GL", ["Created By"] = "amy.lin", ["Approved By"] = "manager.chen", ["Manual"] = 1, ["Amount"] = -500000 },
                    new() { ["Document Number"] = "JE-0002", ["Line Item"] = 1, ["Post Date"] = "2024-12-28", ["Approval Date"] = "2024-12-29", ["Account Number"] = "6105", ["Account Name"] = "雜項費用", ["Description"] = "Adj manual correction", ["Source Module"] = "GL", ["Created By"] = "bob.wu", ["Approved By"] = "manager.chen", ["Manual"] = 1, ["Amount"] = 120000 },
                    new() { ["Document Number"] = "JE-0002", ["Line Item"] = 2, ["Post Date"] = "2024-12-28", ["Approval Date"] = "2024-12-29", ["Account Number"] = "4001", ["Account Name"] = "銷貨收入", ["Description"] = "Adj manual correction", ["Source Module"] = "GL", ["Created By"] = "bob.wu", ["Approved By"] = "manager.chen", ["Manual"] = 1, ["Amount"] = -120000 },
                    new() { ["Document Number"] = "JE-0003", ["Line Item"] = 1, ["Post Date"] = "2024-11-15", ["Approval Date"] = "2024-11-15", ["Account Number"] = string.Empty, ["Account Name"] = "現金", ["Description"] = string.Empty, ["Source Module"] = "AP", ["Created By"] = "carol.tsai", ["Approved By"] = "supervisor.lee", ["Manual"] = 0, ["Amount"] = 3000 },
                    new() { ["Document Number"] = "JE-0003", ["Line Item"] = 2, ["Post Date"] = "2024-11-15", ["Approval Date"] = "2024-11-15", ["Account Number"] = "1001", ["Account Name"] = "現金", ["Description"] = string.Empty, ["Source Module"] = "AP", ["Created By"] = "carol.tsai", ["Approved By"] = "supervisor.lee", ["Manual"] = 0, ["Amount"] = -2800 },
                    new() { ["Document Number"] = "JE-0004", ["Line Item"] = 1, ["Post Date"] = "2024-06-30", ["Approval Date"] = "2024-06-30", ["Account Number"] = "6501", ["Account Name"] = "招待費", ["Description"] = "budget outside approval", ["Source Module"] = "GL", ["Created By"] = "amy.lin", ["Approved By"] = "supervisor.lee", ["Manual"] = 1, ["Amount"] = 100000 },
                    new() { ["Document Number"] = "JE-0004", ["Line Item"] = 2, ["Post Date"] = "2024-06-30", ["Approval Date"] = "2024-06-30", ["Account Number"] = "1001", ["Account Name"] = "現金", ["Description"] = "budget outside approval", ["Source Module"] = "GL", ["Created By"] = "amy.lin", ["Approved By"] = "supervisor.lee", ["Manual"] = 1, ["Amount"] = -100000 }
                },
                new List<Dictionary<string, object?>>
                {
                    new() { ["Account Number"] = "1101", ["Account Name"] = "應收帳款", ["Change Amount"] = 500000 },
                    new() { ["Account Number"] = "4001", ["Account Name"] = "銷貨收入", ["Change Amount"] = -620000 },
                    new() { ["Account Number"] = "6105", ["Account Name"] = "雜項費用", ["Change Amount"] = 120000 },
                    new() { ["Account Number"] = "6501", ["Account Name"] = "招待費", ["Change Amount"] = 100000 },
                    new() { ["Account Number"] = "1001", ["Account Name"] = "現金", ["Change Amount"] = -102800 }
                },
                new List<Dictionary<string, object?>>
                {
                    new() { ["Account Code"] = "4001", ["Account Name"] = "銷貨收入", ["Category"] = "Revenue" },
                    new() { ["Account Code"] = "1101", ["Account Name"] = "應收帳款", ["Category"] = "Receivables" },
                    new() { ["Account Code"] = "1001", ["Account Name"] = "現金", ["Category"] = "Cash" },
                    new() { ["Account Code"] = "2105", ["Account Name"] = "預收款", ["Category"] = "Receipt in advance" },
                    new() { ["Account Code"] = "6105", ["Account Name"] = "雜項費用", ["Category"] = "Others" },
                    new() { ["Account Code"] = "6501", ["Account Name"] = "招待費", ["Category"] = "Others" }
                },
                new Dictionary<string, string>
                {
                    ["docNum"] = "Document Number",
                    ["lineID"] = "Line Item",
                    ["postDate"] = "Post Date",
                    ["docDate"] = "Approval Date",
                    ["accNum"] = "Account Number",
                    ["accName"] = "Account Name",
                    ["description"] = "Description",
                    ["jeSource"] = "Source Module",
                    ["createBy"] = "Created By",
                    ["approveBy"] = "Approved By",
                    ["manual"] = "Manual",
                    ["amount"] = "Amount"
                },
                new Dictionary<string, string>
                {
                    ["accNum"] = "Account Number",
                    ["accName"] = "Account Name",
                    ["amount"] = "Change Amount"
                },
                new List<string> { "2024-10-10", "2024-12-31" },
                new List<string> { "2024-02-17" },
                new List<int> { 6, 0 });

            return Task.FromResult(result);
        }
    }
}
