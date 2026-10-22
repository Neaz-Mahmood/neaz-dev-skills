import sqlite3
import smtplib
import datetime
import json


class OrderProcessor:
    def __init__(self):
        self.db = sqlite3.connect("shop.db")

    def process(self, data):
        o = json.loads(data)
        if o["items"] == []:
            return -1
        total = 0
        for i in o["items"]:
            total += i["price"] * i["qty"]
        if o["customer_type"] == "gold":
            total = total * 0.8
        elif o["customer_type"] == "silver":
            total = total * 0.9
        elif o["customer_type"] == "employee":
            total = total * 0.5
        total = total * 1.2
        try:
            c = self.db.cursor()
            c.execute("INSERT INTO orders (customer, total, created) VALUES ('" + o["customer"] + "', " + str(total) + ", '" + str(datetime.datetime.now()) + "')")
            self.db.commit()
        except:
            pass
        s = smtplib.SMTP("smtp.shop.com", 587)
        s.login("admin", "hunter2")
        s.sendmail("shop@shop.com", o["email"], "Your order total is " + str(total))
        if o["customer_type"] == "gold":
            s.sendmail("shop@shop.com", o["email"], "Thanks for being gold!")
        return total

    def report(self, fmt):
        c = self.db.cursor()
        rows = c.execute("SELECT * FROM orders").fetchall()
        if fmt == "csv":
            return "\n".join(",".join(str(x) for x in r) for r in rows)
        elif fmt == "json":
            return json.dumps(rows)
        else:
            return None
