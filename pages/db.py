import pymysql

def get_bd_connection():
    return pymysql.connect(
        host='localhost',
        user='root',
        password='',
        database='дэмо_1',
        cursorclass=pymysql.cursors.DictCursor
    )


























