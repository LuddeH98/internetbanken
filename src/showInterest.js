const showInterest  = {
    show: async function(rate) {
        const mysql = require("promise-mysql");
        const config = require("../config/internetbanken.json");
        const db = await mysql.createConnection(config);

        rate = rate.trim();

        let str;

        str = await showAccountInterest(db, rate);

        console.log(str);
        return;
    }

};

async function showAccountInterest(db, rate) {
    let sql;
    let res;
    let str;

    sql = `CALL calculateInterest(${rate}, CURRENT_TIMESTAMP());`;

    res = await db.query(sql, [rate]);
    res = res[0];
    str = interestAsTable(res);
    return str;
}

function interestAsTable(res) {
    let str;

    str  = "+------------------------+----------------------------------------";
    str += "----------------------+-----------+\n";
    str += "|  Accumulated interest  |                             Date       ";
    str += "                      |  Bank ID  |\n";
    str += "+------------------------+----------------------------------------";
    str += "----------------------+-----------+\n";

    for (const row of res) {
        str += "|       " + row.rate.toString().padEnd(15);
        str += "  | " + row.date.toString().padEnd(56);
        str += "  |     " + row.id.toString().padEnd(5);
        str += " | \n";
    }
    str += "+------------------------+---------------------------------------";
    str += "-----------------------+-----------+";
    return str;
}

module.exports = showInterest;
