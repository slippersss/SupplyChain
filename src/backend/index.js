const http = require("http");
const url = require("url");
const fs = require('fs');
const childProcess = require("child_process");

const packageFile = "../chainend/nodejs-sdk/packages/api";
const moduleFile = "../chainend/nodejs-sdk/packages/cli/interfaces/base";
const configurationFile = "../chainend/nodejs-sdk/packages/cli/conf/config.json";

const contract = "0xfbdac044bfa49da96a0d8d273674540c10edf6fd"; // Need to be modified
const foobar = "idot";

const Configuration = require(packageFile).Configuration;
const Web3jService = require(packageFile).Web3jService;
const CRUDService = require(packageFile).CRUDService;
const Table = require(packageFile).Table;
const Condition = require(packageFile).Condition;
const GetAbi = require(moduleFile).getAbi;

const configuration = new Configuration(configurationFile);
const web3jService = new Web3jService(configuration);
const crudService = new CRUDService(configuration);

var me_id;
var me_name;

const backend = http.createServer((request, response) => {
    // Debug information
    var url_obj = url.parse(request.url);
    console.log(url_obj.pathname);

    /* Normal part
     * --- register
     * --- login
     */

    // Register
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (id) - `id`
    // ========================================
    if(url_obj.pathname === "/register" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        childProcess.execFile("bash", ["../chainend/utils/register_account.sh"], (err, stdout, stderr) => {
            var temp = stdout.split(":")[1].split("\n")[0].trim().substr(0, 42);
            response.write("{\"status\":0,\"id\":\"" + temp + "\"}", "utf-8");
            response.end();
            return;
        });
    }

    // Login
    // ========================================
    // Argument
    // --- (name) - `String`
    // ========================================
    // Return value
    // --- (-1) - `account not exists`
    // ========================================
    if(url_obj.pathname === "/login" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "text/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                childProcess.execFile("bash", ["../chainend/utils/login_account.sh", argument["name"]], (err, stdout, stderr) => {
                    if(stderr.trim().substr(0, 11) === "read EC key") {
                        me_id = "0x" + stdout.trim().substr(0, 40);
                        me_name = argument["name"];
                        var table = new Table("Account", foobar, "id, name, role, credit");
                        var condition = new Condition();
                        condition.eq("foobar", foobar);
                        condition.eq("id", me_id);
                        crudService.select(table, condition).then((result) => {
                            var temp = result[0]["role"];
                            if(temp === "institution") {
                                response.write("{\"status\":2,\"message\":\"institution_" + me_id + "\"}", "utf-8");
                                response.end();
                            }
                            else if(temp === "enterprise") {
                                response.write("{\"status\":1,\"message\":\"enterprise_" + me_id + "\"}", "utf-8");
                                response.end();
                            }
                            else {
                                response.write("{\"status\":0,\"message\":\"administrator_" + me_id + "\"}", "utf-8");
                                response.end();
                            }
                        });
                    }
                    else {
                        response.write("{\"status\":-1,\"message\":\"account not exists\"}", "utf-8");
                        response.end();
                    }
                    return;
                });
            }
        });        
    }

    /* Administrator part
     * --- selectAccount
     * --- removeAccount
     * --- insertAccount
     */

    // Select account
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (data) - `String`
    // ========================================
    if(url_obj.pathname === "/selectAccount" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var table = new Table("Account", foobar, "id, name, role, credit");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        crudService.select(table, condition).then((result) => {
            var temp = JSON.stringify(result);
            response.write("{\"status\":0,\"data\":" + temp + "}", "utf-8");
            response.end();
            return;
        });
    }

    // Remove account
    // ========================================
    // Argument
    // --- (id) - `String`
    // ========================================
    // Return value
    // --- (none)
    // ========================================
    if(url_obj.pathname === "/removeAccount" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "removeAccountTable");
                web3jService.sendRawTransaction(contract, abi, [argument["id"]], me_name).then((result) => {
                    response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    response.end();
                    return;
                });
            }
        });
    }

    // Insert account
    // ========================================
    // Argument
    // --- (id) - `String`
    // --- (name) - `String`
    // --- (role) - `String`
    // --- (credit) - `Number`
    // ========================================
    // Return value
    // --- (-1) - `credit invalid`
    // --- (-2) - `id exists`
    // --- (-3) - `name exists`
    // ========================================
    if(url_obj.pathname === "/insertAccount" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "insertAccountTable");
                web3jService.sendRawTransaction(contract, abi, [argument["id"], argument["name"], argument["role"], argument["credit"]], me_name).then((result) => {
                    var temp = result.output;
                    if(temp === "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff") {
                        response.write("{\"status\":-1,\"message\":\"credit invalid\"}", "utf-8");
                        response.end();
                    }
                    else if(temp === "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe") {
                        response.write("{\"status\":-2,\"message\":\"id exists\"}", "utf-8");
                        response.end();
                    }
                    else if(temp === "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd") {
                        response.write("{\"status\":-3,\"message\":\"name exists\"}", "utf-8");
                        response.end();
                    }
                    else {
                        response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                        response.end();
                    }
                    return;
                });
            }
        });
    }

    /* Enterprise part
     * --- sign
     * --- confirm
     * --- transfer
     * --- financing
     * --- pay
     * --- selectAccountEnterprise
     * --- selectAccountInstitution
     * --- selectPendBorrower
     * --- selectBillLender
     * --- checkInformation
     */

    // Sign
    // ========================================
    // Argument
    // --- (lender) - `String`
    // --- (witness) - `String`
    // --- (amount) - `Number`
    // --- (duration) - `Number`
    // ========================================
    // Return value
    // --- (-1) - `amount invalid`
    // --- (-2) - `duration invalid`
    // --- (-3) - `credit insufficient`
    // ========================================
    if(url_obj.pathname === "/sign" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "sign");
                web3jService.sendRawTransaction(contract, abi, [argument["lender"], argument["witness"], argument["amount"], argument["duration"]], me_name).then((result) => {
                    var temp = result.output;
                    if(temp === "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff") {
                        response.write("{\"status\":-1,\"message\":\"amount invalid\"}", "utf-8");
                    }
                    else if(temp === "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe") {
                        response.write("{\"status\":-2,\"message\":\"duration invalid\"}", "utf-8");
                    }
                    else if(temp === "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd") {
                        response.write("{\"status\":-3,\"message\":\"credit insufficient\"}", "utf-8");
                    }
                    else {
                        response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    }
                    response.end();
                    return;
                });
            }
        });
    }

    // Confirm
    // ========================================
    // Argument
    // --- (lender) - `String`
    // --- (witness) - `String`
    // --- (timestamp) - `Number`
    // --- (duration) - `Number`
    // ========================================
    // Return value
    // --- (none)
    // ========================================
    if(url_obj.pathname === "/confirm" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "confirm");
                web3jService.sendRawTransaction(contract, abi, [argument["lender"], argument["witness"], argument["timestamp"], argument["duration"]], me_name).then((result) => {
                    response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    response.end();
                    return;
                });
            }
        });
    }

    // Transfer
    // ========================================
    // Argument
    // --- (receiver) - `String`
    // --- (total_amount) - `Number`
    // ========================================
    // Return value
    // --- (-1) - `total_amount invalid`
    // --- (-2) - `asset insufficient`
    // ========================================
    if(url_obj.pathname === "/transfer" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "transfer");
                web3jService.sendRawTransaction(contract, abi, [argument["receiver"], argument["total_amount"]], me_name).then((result) => {
                    var temp = result.output;
                    if(temp === "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff") {
                        response.write("{\"status\":-1,\"message\":\"total_amount invalid\"}", "utf-8");
                    }
                    else if(temp === "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe") {
                        response.write("{\"status\":-2,\"message\":\"asset insufficient\"}", "utf-8");
                    }
                    else {
                        response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    }
                    response.end();
                    return;
                });
            }
        });
    }

    // Financing
    // ========================================
    // Argument
    // --- (institution) - `String`
    // --- (total_amount) - `Number`
    // ========================================
    // Return value
    // --- (-1) - `total_amount invalid`
    // --- (-2) - `asset insufficient`
    // ========================================
    if(url_obj.pathname === "/financing" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "financing");
                web3jService.sendRawTransaction(contract, abi, [argument["institution"], argument["total_amount"]], me_name).then((result) => {
                    var temp = result.output;
                    if(temp === "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff") {
                        response.write("{\"status\":-1,\"message\":\"total_amount invalid\"}", "utf-8");
                    }
                    else if(temp === "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe") {
                        response.write("{\"status\":-2,\"message\":\"asset insufficient\"}", "utf-8");
                    }
                    else {
                        response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    }
                    response.end();
                    return;
                });
            }
        });
    }

    // Pay
    // ========================================
    // Argument
    // --- (lender) - `String`
    // --- (witness) - `String`
    // --- (amount) - `Number`
    // --- (timestamp) - `Number`
    // --- (deadline) - `Number`
    // ========================================
    // Return value
    // --- (none)
    // ========================================
    if(url_obj.pathname === "/pay" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "pay");
                web3jService.sendRawTransaction(contract, abi, [argument["lender"], argument["witness"], argument["amount"], argument["timestamp"], argument["deadline"]], me_name).then((result) => {
                    response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    response.end();
                    return;
                });
            }
        });
    }

    // Select account enterprise
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (data) - `Entries`
    // ========================================
    if(url_obj.pathname === "/selectAccountEnterprise" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var table = new Table("Account", foobar, "id, name, role, credit");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("role", "enterprise");
        crudService.select(table, condition).then((result) => {
            var temp = JSON.stringify(result);
            response.write("{\"status\":0,\"data\":" + temp + "}", "utf-8");
            response.end();
            return;
        });
    }

    // Select account institution
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (data) - `Entries`
    // ========================================
    if(url_obj.pathname === "/selectAccountInstitution" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var table = new Table("Account", foobar, "id, name, role, credit");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("role", "institution");
        crudService.select(table, condition).then((result) => {
            var temp = JSON.stringify(result);
            response.write("{\"status\":0,\"data\":" + temp + "}", "utf-8");
            response.end();
            return;
        });
    }

    // Select pend borrower
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (none)
    // ========================================
    if(url_obj.pathname === "/selectPendBorrower" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var table = new Table("Pend", foobar, "borrower, lender, witness, amount, timestamp, duration, state");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("borrower", me_id);
        crudService.select(table, condition).then((result) => {
            var temp = JSON.stringify(result);
            response.write("{\"status\":0,\"data\":" + temp + "}", "utf-8");
            response.end();
            return;
        });
    }

    // Select bill borrower
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (data) - `Entries`
    // ========================================
    if(url_obj.pathname === "/selectBillBorrower" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var table = new Table("Bill", foobar, "borrower, lender, witness, amount, timestamp, deadline");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("borrower", me_id);
        crudService.select(table, condition).then((result) => {
            var temp = JSON.stringify(result);
            response.write("{\"status\":0,\"data\":" + temp + "}", "utf-8");
            response.end();
            return;
        });
    }

    // Check information
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (data) - `String`
    // ========================================
    if(url_obj.pathname === "/checkInformation" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var temp = 0;
        var table = new Table("Bill", foobar, "borrower, lender, witness, amount, timestamp, deadline");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("lender", me_id);
        crudService.select(table, condition).then((result) => {
            for(var i = 0; i < result.length; ++i) {
                temp += Number(result[i]["amount"]);
            }
        });
        var table = new Table("Account", foobar, "id, name, role, credit");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("id", me_id);
        crudService.select(table, condition).then((result) => {
            response.write("{\"status\":0,\"asset\":" + temp + ",\"credit\":" + result[0]["credit"] + "}");
            response.end();
            return;
        });
    }

    /* Institution part
     * --- selectPendWitness
     * --- permit
     */

    // Select pend witness
    // ========================================
    // Argument
    // --- (none)
    // ========================================
    // Return value
    // --- (none)
    // ========================================
    if(url_obj.pathname === "/selectPendWitness" && request.method === "GET") {
        response.setHeader("content-type", "text/html;charset=utf-8");
        var table = new Table("Pend", foobar, "borrower, lender, witness, amount, timestamp, duration, state");
        var condition = new Condition();
        condition.eq("foobar", foobar);
        condition.eq("witness", me_id);
        condition.eq("state", "pend");
        crudService.select(table, condition).then((result) => {
            var temp = JSON.stringify(result);
            response.write("{\"status\":0,\"data\":" + temp + "}", "utf-8");
            response.end();
            return;
        });
    }

    // Permit
    // ========================================
    // Argument
    // --- (borrower) - `String`
    // --- (lender) - `String`
    // --- (amount) - `Number`
    // --- (timestamp) - `Number`
    // --- (duration) - `Number`
    // ========================================
    // Return value
    // --- (none)
    // ========================================
    if(url_obj.pathname === "/permit" && request.method === "POST") {
        var argument = "";
        request.on("data", (chunk) => {
            argument += chunk;
        });
        response.setHeader("content-type", "test/html;charset=utf-8");
        request.on("end", (error) => {
            if(!error) {
                argument = JSON.parse(argument);
                var abi = GetAbi("SupplyChain", "permit");
                web3jService.sendRawTransaction(contract, abi, [argument["borrower"], argument["lender"], argument["amount"], argument["timestamp"], argument["duration"]], me_name).then((result) => {
                    response.write("{\"status\":0,\"message\":\"ok\"}", "utf-8");
                    response.end();
                    return;
                });
            }
        });
    }
    
    render('../frontend/' + url_obj.pathname, response);
});

var port = 80;
backend.listen(port, (error) => {
    if(!error){
        console.log('port ' + port + ' listening...');
    }
});

function render(path, response) {
    fs.readFile(path, 'binary', (error,data) => {
        if(!error){
            response.write(data, 'binary');
            response.end();
        }
    })
}