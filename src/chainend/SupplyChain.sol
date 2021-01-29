pragma solidity >= 0.4.24 < 0.6.11;

import "./Table.sol";

contract SupplyChain
{
    /* Fixed frame code
     * --- variable    状态变量
     * --- event       事件
     * --- modifier    修饰器
     * --- constructor 构建方法
     */

    // 状态变量
    address private administrator;

    // 事件
    event signEvent(string borrower, string lender, string witness, int amount, int timestamp, int duration, string state);
    event confirmEvent(string borrower, string lender, string witness, int timestamp, int duration);
    event transferEvent(string sender, string receiver, int total_amount);
    event financingEvent(string enterprise, string institution, int total_amount);
    event payEvent(string borrower, string lender, string witness, int amount, int timestamp, int deadline);
    event permitEvent(string borrower, string lender, string witness, int amount, int timestamp, int duration);

    // 修饰器
    modifier onlyAdministrator
    {
        require(administrator == msg.sender, "Auth: only administrator is authorized.");
        _;
    }

    // 构建方法
    constructor () public
    {
        administrator = msg.sender;
    }

    /* Helper function
     * --- stringCompare   比较字符串
     * --- encode          编码
     * --- addressToString 转化地址为字符串
     */

    // 辅助函数，比较字符串
    function stringCompare(string memory a, string memory b) private pure returns(bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // 辅助函数，编码
    function encode(uint8 num) private pure returns(byte)
    {
        if(num >= 0 && num <= 9)
        {
            return byte(num + 48);
        }
        else
        {
            return byte(num + 87);
        }
    }

    // 辅助函数，转化地址为字符串
    function addressToString(address addr) private pure returns(string memory)
    {
        // Convert addr to bytes
        bytes20 value = bytes20(uint160(addr));
        bytes memory strBytes = new bytes(42);
        // Encode hex prefix
        strBytes[0] = '0';
        strBytes[1] = 'x';
        // Encode bytes using hex encoding
        for(uint i = 0; i < 20; ++i)
        {
            uint8 byteValue = uint8(value[i]);
            strBytes[2 + (i << 1)] = encode(byteValue >> 4);
            strBytes[3 + (i << 1)] = encode(byteValue & 0x0f);
        }
        return string(strBytes);
    }

    /* Account table structure
     * -------------------------------------
     * | `id` | `name` | `role` | `credit` |
     * -------------------------------------
     * --- id     账户地址
     * --- name   账户名字
     * --- role   账户角色
     * --- credit 账户信用分
     */

    // 账户表的创建操作
    // 注：这一部分代码没有检查表是否存在，使用时需要稍加注意，待修改
    // 主要是管理员会涉及此操作
    function createAccountTable() public onlyAdministrator returns(int)
    {
        int value = TableFactory(0x1001).createTable("Account", "foobar", "id, name, role, credit");
        return value;
    }

    // 账户表的插入操作
    // 主要是管理员会涉及此操作
    // 返回值
    // -1 表明 credit 无效
    // -2 表明 id 重复
    // -3 表明 name 重复
    function insertAccountTable(string memory id, string memory name, string memory role, int credit) public onlyAdministrator returns(int)
    {
        if(credit < 0 || credit > 100) {
            return -1; // credit 无效
        }
        Table table = TableFactory(0x1001).openTable("Account");
        string memory foobar = "idot";
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("id", id);
        Entries entries = table.select(foobar, condition);
        if(entries.size() != 0)
        {
            return -2; // id 重复
        }
        condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("name", name);
        entries = table.select(foobar, condition);
        if(entries.size() != 0)
        {
            return -3; // name 重复
        }
        Entry entry = table.newEntry();
        entry.set("foobar", foobar);
        entry.set("id", id);
        entry.set("name", name);
        entry.set("role", role);
        entry.set("credit", credit);
        int value = table.insert(foobar, entry);
        return value;
    }

    // 账户表的删除操作
    // 主要是管理员会涉及此操作
    function removeAccountTable(string memory id) public onlyAdministrator returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Account");
        string memory foobar = "idot";
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("id", id);
        int value = table.remove(foobar, condition);
        return value;
    }

    // 账户表的更新操作
    // 主要是企业会涉及此操作
    // 调用者应该是 pay 函数
    // 根据 | `id` | 字段查询记录
    // 目的是更新 | `credit` | 字段
    function updateAccountTable(string memory id, int new_credit) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Account");
        string memory foobar = "idot";
        Entry entry = table.newEntry();
        entry.set("credit", new_credit);
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("id", id);
        int value = table.update(foobar, entry, condition);
        return value;
    }

    // 账户表的查询操作
    // 主要是企业会涉及此操作
    // 调用者应该是 sign 和 confirm 和 transfer 和 financing 和 permit 函数
    // 根据 | `id` | 字段查询记录
    // 目的是查询记录
    function selectAccountTable(string memory id) private returns(Entries)
    {
        Table table = TableFactory(0x1001).openTable("Account");
        string memory foobar = "idot";
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("id", id);
        Entries entries = table.select(foobar, condition);
        return entries;
    }

    /* Pend table structure
     * -------------------------------------------------------------------------------------
     * | `borrower` | `lender` | `witness` | `amount` | `timestamp` | `duration` | `state` |
     * -------------------------------------------------------------------------------------
     * --- borrower  借款方
     * --- lender    被借款方
     * --- witness   见证机构
     * --- amount    金额
     * --- timestamp 借款发起时的时间戳
     * --- duration  借款时长
     * --- state     借款状态
     */
    
    // 等待表的创建操作
    // 主要是管理员会涉及此操作
    function createPendTable() public onlyAdministrator returns(int)
    {
        int value = TableFactory(0x1001).createTable("Pend", "foobar", "borrower, lender, witness, amount, timestamp, duration, state");
        return value;
    }

    // 等待表的插入操作
    // 主要是企业会涉及此操作
    // 调用者应该是 sign 函数
    // 根据 | `borrower` | `lender` | `witness` | `amount` | `timestamp` | `duration` | `state` | 字段新建记录
    // 目的是插入记录
    function insertPendTable(string memory borrower, string memory lender, string memory witness, int amount, int timestamp, int duration, string memory state) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Pend");
        string memory foobar = "idot";
        Entry entry = table.newEntry();
        entry.set("foobar", foobar);
        entry.set("borrower", borrower);
        entry.set("lender", lender);
        entry.set("witness", witness);
        entry.set("amount", amount);
        entry.set("timestamp", timestamp);
        entry.set("duration", duration);
        entry.set("state", state);
        int value = table.insert(foobar, entry);
        return value;
    }

    // 等待表的删除操作
    // 主要是企业会涉及此操作
    // 调用者应该是 confirm 函数
    // 根据 | `borrower` | `lender` | `witness` | `timestamp` | `duration` | 字段查询记录
    // 目的是删除记录
    function removePendTable(string memory borrower, string memory lender, string memory witness, int timestamp, int duration) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Pend");
        string memory foobar = "idot";
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("borrower", borrower);
        condition.EQ("lender", lender);
        condition.EQ("witness", witness);
        condition.EQ("timestamp", timestamp);
        condition.EQ("duration", duration);
        int value = table.remove(foobar, condition);
        return value;
    }
    
    // 等待表的更新操作
    // 主要是机构会涉及此操作
    // 调用者应该是 permit 函数
    // 根据 | `borrower` | `lender` | `witness` | `timestamp` | `duration` | 字段查询记录
    // 目的是更新 | `state` | 字段
    function updatePendTable(string memory borrower, string memory lender, string memory witness, int timestamp, int duration, string memory new_state) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Pend");
        string memory foobar = "idot";
        Entry entry = table.newEntry();
        entry.set("state", new_state);
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("borrower", borrower);
        condition.EQ("lender", lender);
        condition.EQ("witness", witness);
        condition.EQ("timestamp", timestamp);
        condition.EQ("duration", duration);
        int value = table.update(foobar, entry, condition);
        return value;
    }

    /* Bill table structure
     * ---------------------------------------------------------------------------
     * | `borrower` | `lender` | `witness` | `amount` | `timestamp` | `deadline` |
     * ---------------------------------------------------------------------------
     * --- borrower  借款方
     * --- lender    被借款方
     * --- witness   见证机构
     * --- amount    借款金额
     * --- timestamp 借款形成时的时间戳
     * --- deadline  借款期限
     */

    // 账单表的创建操作
    // 主要是管理员会涉及此操作
    function createBillTable() public onlyAdministrator returns(int)
    {
        int value = TableFactory(0x1001).createTable("Bill", "foobar", "borrower, lender, witness, amount, timestamp, deadline");
        return value;
    }

    // 账单表的插入操作
    // 主要是机构会涉及此操作
    // 调用者应该是 permit 函数
    // 根据 | `borrower` | `lender` | `witness` | `amount` | `timestamp` | `deadline` | 字段新建记录
    // 目的是插入记录
    function insertBillTable(string memory borrower, string memory lender, string memory witness, int amount, int timestamp, int deadline) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Bill");
        string memory foobar = "idot";
        Entry entry = table.newEntry();
        entry.set("foobar", foobar);
        entry.set("borrower", borrower);
        entry.set("lender", lender);
        entry.set("witness", witness);
        entry.set("amount", amount);
        entry.set("timestamp", timestamp);
        entry.set("deadline", deadline);
        int value = table.insert(foobar, entry);
        return value;
    }

    // 账单表的插入操作
    // 注：这一部分代码是重载，本质是为了进行更新操作
    // 主要是企业会涉及此操作
    // 调用者应该是 transfer 和 financing 函数
    // 根据记录查询记录
    // 目的是合并和插入记录
    function insertBillTable(Entry entry, string memory new_lender, int new_amount) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Bill");
        string memory foobar = "idot";
        string memory borrower = entry.getString("borrower");
        string memory witness = entry.getString("witness");
        int timestamp = entry.getInt("timestamp");
        int deadline = entry.getInt("deadline");
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("borrower", borrower);
        condition.EQ("lender", new_lender);
        condition.EQ("witness", witness);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        Entries entries = table.select(foobar, condition);
        int amount = 0;
        if(entries.size() != 0)
        {
            amount = entries.get(0).getInt("amount");
            table.remove(foobar, condition);
        }
        Entry new_entry = table.newEntry();
        entry.set("foobar", foobar);
        new_entry.set("borrower", borrower);
        new_entry.set("lender", new_lender);
        new_entry.set("witness", witness);
        new_entry.set("amount", amount + new_amount);
        new_entry.set("timestamp", timestamp);
        new_entry.set("deadline", deadline);
        int value = table.insert(foobar, new_entry);
        return value;
    }

    // 账单表的删除操作
    // 主要是企业会涉及此操作
    // 调用者应该是 pay 函数
    // 根据 | `borrower` | `lender` | `witness` | `timestamp` | `deadline` | 字段查询记录
    // 目的是删除记录
    function removeBillTable(string memory borrower, string memory lender, string memory witness, int timestamp, int deadline) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Bill");
        string memory foobar = "idot";
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("borrower", borrower);
        condition.EQ("lender", lender);
        condition.EQ("witness", witness);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        int value = table.remove(foobar, condition);
        return value;
    }

    // 账单表的删除操作
    // 注：这一部分代码是重载，为了删除一整个记录
    // 主要是企业会涉及此操作
    // 调用者应该是 transfer 和 financing 函数
    // 根据记录查询记录
    // 目的是删除记录
    function removeBillTable(Entry entry) private returns(int)
    {
        Table table = TableFactory(0x1001).openTable("Bill");
        string memory foobar = "idot";
        string memory borrower = entry.getString("borrower");
        string memory lender = entry.getString("lender");
        string memory witness = entry.getString("witness");
        int timestamp = entry.getInt("timestamp");
        int deadline = entry.getInt("deadline");
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("borrower", borrower);
        condition.EQ("lender", lender);
        condition.EQ("witness", witness);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        int value = table.remove(foobar, condition);
        return value;
    }

    // 账单表的查询操作
    // 主要是企业会涉及此操作
    // 调用者应该是 transfer 和 financing 函数
    // 根据 | `lender` | 字段查询记录
    // 目的是查询记录
    function selectBillTable(string memory lender) private returns(Entries)
    {
        Table table = TableFactory(0x1001).openTable("Bill");
        string memory foobar = "idot";
        Condition condition = table.newCondition();
        condition.EQ("foobar", foobar);
        condition.EQ("lender", lender);
        Entries entries = table.select(foobar, condition);
        return entries;
    }

    /* SupplyChain operation
     * - sign      签发
     * - confirm   确认
     * - transfer  转让
     * - financing 融资
     * - pay       支付
     * - permit    批准
     */

    // 签发操作
    // 返回值
    // -1 表明
    // -2 表明
    // -3 表明信用分不足
    function sign(string memory lender, string memory witness, int amount, int duration) public returns(int)
    {
        if(amount < 0)
        {
            return -1; // amount 
        }
        if(duration < 0)
        {
            return -2; // duration 
        }
        string memory borrower = addressToString(msg.sender);
        Entries entries_borrower = selectAccountTable(borrower);
        if(entries_borrower.get(0).getInt("credit") < 60)
        {
            return -3; // borrower 信用分不足
        }
        int timestamp = int(now);
        string memory state = "pend";
        insertPendTable(borrower, lender, witness, amount, timestamp, duration, state);
        emit signEvent(borrower, lender, witness, amount, timestamp, duration, state);
        return 0;
    }

    // 确认操作
    function confirm(string memory lender, string memory witness, int timestamp, int duration) public returns(int)
    {
        string memory borrower = addressToString(msg.sender);
        removePendTable(borrower, lender, witness, timestamp, duration);
        emit confirmEvent(borrower, lender, witness, timestamp, duration);
        return 0;
    }

    // 转让操作
    // 返回值
    // -1
    // -2 表明资产不足
    function transfer(string memory receiver, int total_amount) public returns(int)
    {
        if(total_amount < 0)
        {
            return -1;
        }
        string memory sender = addressToString(msg.sender);
        Entries entries = selectBillTable(sender);
        int index = 0;
        int asset = 0;
        int i;
        for(i = 0; i < entries.size(); ++i)
        {
            asset += entries.get(i).getInt("amount");
            if(asset >= total_amount)
            {
                index = i + 1;
                break;
            }
        }
        if(asset < total_amount)
        {
            return -2; // 没有足够资产转让
        }
        int amount;
        for(i = 0; i < index - 1; ++i)
        {
            amount = entries.get(i).getInt("amount");
            removeBillTable(entries.get(i));
            insertBillTable(entries.get(i), receiver, amount);
        }
        amount = entries.get(index - 1).getInt("amount");
        removeBillTable(entries.get(index - 1));
        if(asset == total_amount)
        {
            insertBillTable(entries.get(index - 1), receiver, amount);
        }
        else
        {
            insertBillTable(entries.get(index - 1), receiver, amount - asset + total_amount);
            insertBillTable(entries.get(index - 1), sender, asset - total_amount);
        }
        emit transferEvent(sender, receiver, total_amount);
        return 0;
    }

    // 融资操作
    // 返回值
    // -1
    // -2 表明资产不足
    function financing(string memory institution, int total_amount) public returns(int)
    {
        if(total_amount < 0)
        {
            return -1;
        }
        string memory enterprise = addressToString(msg.sender);
        Entries entries = selectBillTable(enterprise);
        int index = 0;
        int asset = 0;
        int i;
        for(i = 0; i < entries.size(); ++i)
        {
            asset += entries.get(i).getInt("amount");
            if(asset >= total_amount)
            {
                index = i + 1;
                break;
            }
        }
        if(asset < total_amount)
        {
            return -2; // 没有足够资产融资
        }
        int amount;
        for(i = 0; i < index - 1; ++i)
        {
            amount = entries.get(i).getInt("amount");
            removeBillTable(entries.get(i));
            insertBillTable(entries.get(i), institution, amount);
        }
        amount = entries.get(index - 1).getInt("amount");
        removeBillTable(entries.get(index - 1));
        if(asset == total_amount)
        {
            insertBillTable(entries.get(index - 1), institution, amount);
        }
        else
        {
            insertBillTable(entries.get(index - 1), institution, amount - asset + total_amount);
            insertBillTable(entries.get(index - 1), enterprise, asset - total_amount);
        }
        emit financingEvent(enterprise, institution, total_amount);
        return 0;
    }

    // 支付操作
    function pay(string memory lender, string memory witness, int amount, int timestamp, int deadline) public returns(int)
    {
        string memory borrower = addressToString(msg.sender);
        Entries entries_borrower = selectAccountTable(borrower);
        int credit = entries_borrower.get(0).getInt("credit");
        uint time = now;
        if(time >= uint(deadline)) // 超时减信用分
        {
            updateAccountTable(borrower, credit - 1);
        }
        else // 守时加信用分
        {
            updateAccountTable(borrower, credit + 1);
        }
        removeBillTable(borrower, lender, witness, timestamp, deadline);
        emit payEvent(borrower, lender, witness, amount, timestamp, deadline);
        return 0;
    }

    // 批准操作
    function permit(string memory borrower, string memory lender, int amount, int timestamp, int duration) public returns(int)
    {
        string memory witness = addressToString(msg.sender);
        string memory state = "pass";
        updatePendTable(borrower, lender, witness, timestamp, duration, state); // 等待表删除记录
        int new_timestamp = int(now);
        int deadline = new_timestamp + (duration * 1 days) * 1000;
        insertBillTable(borrower, lender, witness, amount, new_timestamp, deadline); // 账单表插入记录
        emit permitEvent(borrower, lender, witness, amount, new_timestamp, duration);
        return 0;
    }
}