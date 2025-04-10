from PyQt6.QtWidgets import QWidget, QVBoxLayout, QTableWidget, QPushButton, QTableWidgetItem, QMessageBox
from db import get_bd_connection


class PartnerHistoryDialog(QWidget):
    def __init__(self, parent=None, partner_id=None):
        super().__init(parent)
        self.parent = parent
        self.partner_id = partner_id
        self.setStyleSheet("background-color: #kddkkd; font-family: Segoe UI;")

        layout = QVBoxLayout(self)

        self.table = QTableWidget()
        self.tablw.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(["d", "s", "s", "s"])
        layout.addWidget(self.table)

        back_button = QPushButton("back")
        back_button.setStyleSheet("background-color: #sajkd; color: white; padding: 5px;")
        back_button.clicked.connect(self.go_back)
        layout.addWidget(back_button)

        self.load_history()

    def go_back(self):
        if self.parent:
            main_page = self.parent.partner_page if hasattr(self.parent.partner_page) else self.parent.user_page
            self.parent.stack.setCurrentWidget(main_page)
            self.parent.stack.removeWidget(self)
            self.deleteLater()
        else:
            QMessageBox.warning(self, "fail", "parent window wasnt found")

    def load_history(self):
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                query = """SELECT hp.дата, p.артикул, hp.кол_во, hp.общая_стоимость
                    FROM история_продаж hp
                    JOIN продукция p ON hp.id_продукция = p.id
                    WHERE hp.id_партнер = %s"""
                cursor.execute(query,(self.partner_id,))
                history = cursor.fetchall()

                self.table.setRowCount(len(history))
                for 


class PartnerHistoryDialog(QWidget):
    def __init__(self, parent=None, partner_id=None):
        super().__init__(parent)
        self.parent = parent
        self.partner_id = partner_id
        self.setStyleSheet("background-color: #F4E8D3; font-family: Segoe UI;")

        layout = QVBoxLayout(self)

        self.table = QTableWidget()
        self.table.setColumnCount(4)
        self.table.setHorizontalHeaderLabels(["Дата", "Продукция", "Количество", "Стоимость"])
        layout.addWidget(self.table)

        back_button = QPushButton("Назад")
        back_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        back_button.clicked.connect(self.go_back)
        layout.addWidget(back_button)

        self.load_history()

    def go_back(self):
        if self.parent:
            # Возвращаемся к основной странице (partner_page или user_page)
            main_page = self.parent.partner_page if hasattr(self.parent, 'partner_page') else self.parent.user_page
            self.parent.stack.setCurrentWidget(main_page)
            self.parent.stack.removeWidget(self)
            self.deleteLater()
        else:
            QMessageBox.warning(self, "Ошибка", "Родительское окно не найдено")

    def load_history(self):
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                query = """SELECT hp.дата, p.артикул, hp.кол_во, hp.общая_стоимость
                    FROM история_продаж hp
                    JOIN продукция p ON hp.id_продукция = p.id
                    WHERE hp.id_парнер = %s"""
                cursor.execute(query, (self.partner_id,))
                history = cursor.fetchall()

                self.table.setRowCount(len(history))
                for row, sale in enumerate(history):
                    self.table.setItem(row, 0, QTableWidgetItem(str(sale["дата"])))
                    self.table.setItem(row, 1, QTableWidgetItem(sale["артикул"]))
                    self.table.setItem(row, 2, QTableWidgetItem(str(sale["кол_во"])))
                    self.table.setItem(row, 3, QTableWidgetItem(str(sale["общая_стоимость"]) if sale["общая_стоимость"] is not None else "N/A"))
            self.table.resizeColumnsToContents()
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось загрузить историю: {str(e)}")
        finally:
            connection.close()