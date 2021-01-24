pragma solidity >= 0.4.24 < 0.6.11;

import "./Table.sol";

contract SupplyChain
{
    /* Fixed frame code
     * - variable
     * - event
     * - modifier
     */

    // 状态变量
    address private god;

    // 事件
    event signEvent(address borrower, address lender, address witness, int amount, int timestamp, int deadline);
    event transferEvent(address sender, address receiver, int amount);
    event financingEvent(address enterprise, address instituation, int amount);
    event payEvent(address borrower, address lender, address witness, int amount, int timestamp, int deadline);

    // 修饰器
    modifier onlyGod
    {
        require(god == msg.sender, "Auth: only god is authorized.");
        _;
    }

    // 构建方法
    constructor () public
    {
        god = msg.sender;
    }

    /* Helper function
     * - stringCompare
     * - encode
     * - addressToString
     */

    // 辅助函数，比较字符串
    function stringCompare(string a, string b) private pure returns(bool)
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
    function addressToString(address addr) private pure returns(string)
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
     * -----------------------------
     * | id | name | role | credit |
     * -----------------------------
     */

    // 账户表的创建操作
    // 注：这一部分代码没有检查表是否存在，使用时需要稍加注意，待修改
    function createAccountTable() public onlyGod returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        int value = tf.createTable("Account", "id", "name, role, credit");
        return value;
    }

    // 账户表的插入操作
    function insertAccountTable(address id, string name, string role, int credit) public onlyGod returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Account");
        string memory id_str = addressToString(id);
        Condition condition = table.newCondition();
        condition.EQ("id", id_str);
        Entries entries = table.select(id_str, condition);
        if(entries.size() == 0)
        {
            return -1; // id 重复
        }
        condition = table.newCondition();
        condition.EQ("name", name);
        entries = table.select(name, condition);
        if(entries.size() == 0)
        {
            return -2; // name 重复
        }
        Entry entry = table.newEntry();
        entry.set("id", id_str);
        entry.set("name", name);
        entry.set("role", role);
        entry.set("credit", credit);
        int value = table.insert(id_str, entry);
        return value;
    }

    // 账户表的删除操作
    function removeAccountTable(address id) public onlyGod returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Account");
        string memory id_str = addressToString(id);
        Condition condition = table.newCondition();
        condition.EQ("id", id_str);
        int value = table.remove(id_str, condition);
        return value;
    }

    // 账户表的更新操作
    function updateAccountTable(address id, int new_credit) private returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Account");
        Entry entry = table.newEntry();
        entry.set("credit", new_credit);
        string memory id_str = addressToString(id);
        Condition condition = table.newCondition();
        condition.EQ("id", id_str);
        int value = table.update(id_str, entry, condition);
        return value;
    }

    // 账户表的查询操作
    function selectAccountTable(address id) private returns(Entries)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Account");
        string memory id_str = addressToString(id);
        Condition condition = table.newCondition();
        condition.EQ("id", id_str);
        Entries entries = table.select(id_str, condition);
        return entries;
    }

    /* Bill table structure
     * ---------------------------------------------------------------
     * | lender | borrower | witness | amount | timestamp | deadline |
     * ---------------------------------------------------------------
     */

    // 账单表的创建操作
    function createBillTable() public onlyGod returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        int value = tf.createTable("Bill", "lender", "borrower, witness, amount, timestamp, deadline");
        return value;
    }

    // 账单表的插入操作
    function insertBillTable(address lender, address borrower, address witness, int amount, int timestamp, int deadline) private returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Bill");
        string memory lender_str = addressToString(lender);
        string memory borrower_str = addressToString(borrower);
        string memory witness_str = addressToString(witness);
        Condition condition = table.newCondition();
        condition.EQ("lender", lender_str);
        condition.EQ("borrower", borrower_str);
        condition.EQ("witness", witness_str);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        Entries entries = table.select(lender_str, condition);
        int old_amount = 0;
        if(entries.size() != 0)
        {
            old_amount = entries.get(0).getInt("amount");
            table.remove(lender_str, condition);
        }
        Entry entry = table.newEntry();
        entry.set("lender", lender_str);
        entry.set("borrower", borrower_str);
        entry.set("witness", witness_str);
        entry.set("amount", amount + old_amount);
        entry.set("timestamp", timestamp);
        entry.set("deadline", deadline);
        int value = table.insert(lender_str, entry);
        return value;
    }

    // 账单表的插入操作
    // 注：这一部分代码是重载，有特殊的用途，与其说是插入操作，不如说是更新操作，其本质是更新操作
    function insertBillTable(Entry entry, address new_lender, int new_amount) private returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Bill");
        string memory lender_str = addressToString(new_lender);
        string memory borrower_str = entry.getString("borrower");
        string memory witness_str = entry.getString("witness");
        int timestamp = entry.getInt("timestamp");
        int deadline = entry.getInt("deadline");
        Condition condition = table.newCondition();
        condition.EQ("lender", lender_str);
        condition.EQ("borrower", borrower_str);
        condition.EQ("witness", witness_str);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        Entries entries = table.select(lender_str, condition);
        int old_amount = 0;
        if(entries.size() != 0)
        {
            old_amount = entries.get(0).getInt("amount");
            table.remove(lender_str, condition);
        }
        Entry new_entry = table.newEntry();
        new_entry.set("lender", lender_str);
        new_entry.set("borrower", borrower_str);
        new_entry.set("witness", witness_str);
        new_entry.set("amount", new_amount + old_amount);
        new_entry.set("timestamp", timestamp);
        new_entry.set("deadline", deadline);
        int value = table.insert(lender_str, new_entry);
        return value;
    }

    // 账单表的删除操作
    function removeBillTable(Entry entry) private returns(int)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Bill");
        string memory lender_str = entry.getString("lender");
        string memory borrower_str = entry.getString("borrower");
        string memory witness_str = entry.getString("witness");
        int timestamp = entry.getInt("timestamp");
        int deadline = entry.getInt("deadline");
        Condition condition = table.newCondition();
        condition.EQ("lender", lender_str);
        condition.EQ("borrower", borrower_str);
        condition.EQ("witness", witness_str);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        int value = table.remove(lender_str, condition);
        return value;
    }

    // 账单表的查询操作
    function selectBillTable(address lender, address borrower, address witness, int timestamp, int deadline) private returns(Entries)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Bill");
        string memory lender_str = addressToString(lender);
        string memory borrower_str = addressToString(borrower);
        string memory witness_str = addressToString(witness);
        Condition condition = table.newCondition();
        condition.EQ("lender", lender_str);
        condition.EQ("borrower", borrower_str);
        condition.EQ("witness", witness_str);
        condition.EQ("timestamp", timestamp);
        condition.EQ("deadline", deadline);
        Entries entries = table.select(lender_str, condition);
        return entries;
    }

    // 账单表的查询操作
    // 这一部分代码是重载，放松选择条件，查看指定借款方的所有账单
    function selectBillTable(address lender) private returns(Entries)
    {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("Bill");
        string memory lender_str = addressToString(lender);
        Condition condition = table.newCondition();
        condition.EQ("lender", lender_str);
        Entries entries = table.select(lender_str, condition);
        return entries;
    }

    /* SupplyChain operations
     * - sign
     * - transfer
     * - financing
     * - pay
     */

    // 签发操作
    function sign(address lender, address witness, int amount, int duration) public returns(int)
    {
        // 考虑 borrower 和 lender 和 witness 的存在性
        // 考虑 borrower 和 lender 是否为企业，witness 是否为金融机构
        // 考虑 borrower 信用分足够与否
        Entries entries_borrower = selectAccountTable(msg.sender);
        Entries entries_lender = selectAccountTable(lender);
        Entries entries_witness = selectAccountTable(witness);
        if(entries_borrower.size() == 0)
        {
            return -1; // borrower 不存在
        }
        if(entries_lender.size() == 0)
        {
            return -2; // lender 不存在
        }
        if(entries_witness.size() == 0)
        {
            return -3; // witness 不存在
        }
        if(!stringCompare(entries_borrower.get(0).getString("role"), "enterprise"))
        {
            return -4; // borrower 非企业
        }
        if(!stringCompare(entries_lender.get(0).getString("role"), "enterprise"))
        {
            return -5; // lender 非企业
        }
        if(!stringCompare(entries_witness.get(0).getString("role"), "institution"))
        {
            return -6; // witness 非金融机构
        }
        if(entries_borrower.get(0).getInt("credit") < 60)
        {
            return -7; // borower 信用分不足
        }
 
        // 主要代码逻辑
        int timestamp = int(now);
        int deadline = timestamp + duration * 1 days;
        int value = insertBillTable(lender, msg.sender, witness, amount, timestamp, deadline);
        emit signEvent(msg.sender, lender, witness, amount, timestamp, deadline);
        return 0;
    }

    // 转让操作
    function transfer(address receiver, int total_amount) public returns(int)
    {
        // 考虑 sender 和 receiver 的存在性
        // 考虑 sender 和 receiver 是否为企业
        Entries entries_sender = selectAccountTable(msg.sender);
        Entries entries_receiver = selectAccountTable(receiver);
        if(entries_sender.size() == 0)
        {
            return -1; // sender 不存在
        }
        if(entries_receiver.size() == 0)
        {
            return -2; // receiver 不存在
        }
        if(!stringCompare(entries_sender.get(0).getString("role"), "enterprise"))
        {
            return -3; // sender 非企业
        }
        if(!stringCompare(entries_receiver.get(0).getString("role"), "enterprise"))
        {
            return -4; // receiver 非企业
        }

        // 主要代码逻辑
        Entries entries = selectBillTable(msg.sender);
        int index = 0;
        int asset = 0;
        for(int i = 0; i < entries.size(); ++i)
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
            return -5; // 没有足够资产转让
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
            insertBillTable(entries.get(index - 1), msg.sender, asset - total_amount);
        }
        emit transferEvent(msg.sender, receiver, total_amount);
        return 0;
    }

    // 融资操作
    function financing(address institution, int total_amount) public returns(int)
    {
        // 考虑 enterprise 和 institution 的存在性
        // 考虑 enterprise 是否为企业，institution 是否为金融机构
        Entries entries_enterprise = selectAccountTable(msg.sender);
        Entries entries_institution = selectAccountTable(institution);
        if(entries_enterprise.size() == 0)
        {
            return -1; // enterprise 不存在
        }
        if(entries_institution.size() == 0)
        {
            return -2; // institution 不存在
        }
        if(!stringCompare(entries_enterprise.get(0).getString("role"), "enterprise"))
        {
            return -3; // enterprise 非企业
        }
        if(!stringCompare(entries_institution.get(0).getString("role"), "institution"))
        {
            return -4; // institution 非金融机构
        }

        // 主要代码逻辑
        Entries entries = selectBillTable(msg.sender);
        int index = 0;
        int asset = 0;
        for(int i = 0; i < entries.size(); ++i)
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
            return -5; // 没有足够资产融资
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
            insertBillTable(entries.get(index - 1), msg.sender, asset - total_amount);
        }
        emit financingEvent(msg.sender, institution, total_amount);
        return 0;
    }

    // 支付操作
    function pay(address lender, address witness, int timestamp, int deadline) public returns(int)
    {
        // 考虑账单的存在性
        Entries entries = selectBillTable(lender, msg.sender, witness, timestamp, deadline);
        if(entries.size() == 0)
        {
            return -1; // 账单不存在
        }
        if(entries.size() >= 2)
        {
            return -2; // 账单不唯一，重大错误，有待解决 ?????????? 更新，此次修改后应该没有了，后面看要不要删掉
        }

        // 主要代码逻辑
        Entries entries_borrower = selectAccountTable(msg.sender);
        int credit = entries_borrower.get(0).getInt("credit");
        uint time = now;
        if(time >= uint(deadline)) // 超时减信用分
        {
            updateAccountTable(msg.sender, credit - 1);
        }
        else // 守时加信用分
        {
            updateAccountTable(msg.sender, credit + 1);
        }
        int amount = entries.get(0).getInt("amount");
        int value = removeBillTable(entries.get(0));
        emit payEvent(msg.sender, lender, witness, amount, timestamp, deadline);
        return 0;
    }

    // 确认操作 ?????????? 更新，我不想做了，没必要
}