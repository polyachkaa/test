from PyQt6.QtWidgets import QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QTableWidget, QTableWidgetItem, QPushButton, QMessageBox, QStackedWidget, QLabel
from PyQt6.QtGui import QIcon, QPixmap
from PyQt6.QtCore import Qt
from db import get_bd_connection
from history_dialog import PartnerHistoryDialog

class UserWindow(QMainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent = parent
        self.setWindowTitle("Просмотр партнеров - Мастер Пол")
        self.setGeometry(500, 500, 500, 500)
        self.setWindowIcon(QIcon("Мастер пол.png"))
        self.setStyleSheet("background-color: #FFFFFF; font-family: Segoe UI;")

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.stack = QStackedWidget()
        layout = QVBoxLayout(self.central_widget)
        layout.addWidget(self.stack)

        self.user_page = QWidget()
        self.init_user_page()
        self.stack.addWidget(self.user_page)

        self.load_partners()

    def init_user_page(self):
        layout = QVBoxLayout(self.user_page)

        logo_label = QLabel()
        logo_pixmap = QPixmap("Мастер пол.png")
        logo_label.setPixmap(logo_pixmap.scaled(150, 50, Qt.AspectRatioMode.KeepAspectRatio))
        layout.addWidget(logo_label, alignment=Qt.AlignmentFlag.AlignCenter)

        self.partner_table = QTableWidget()
        self.partner_table.setColumnCount(6)
        self.partner_table.setHorizontalHeaderLabels(["ID", "Название", "ИНН", "Рейтинг", "Скидка", "Объем продаж"])
        self.partner_table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.partner_table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.partner_table.cellDoubleClicked.connect(self.show_partner_history)
        layout.addWidget(self.partner_table)

        button_layout = QHBoxLayout()
        refresh_button = QPushButton("Обновить")
        back_button = QPushButton("Назад")
        refresh_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        back_button.setStyleSheet("background-color: #D9534F; color: white; padding: 5px;")
        refresh_button.clicked.connect(self.load_partners)
        back_button.clicked.connect(self.go_back)
        button_layout.addWidget(refresh_button)
        button_layout.addWidget(back_button)
        layout.addLayout(button_layout)

    def go_back(self):
        if self.parent:
            self.parent.stack.setCurrentWidget(self.parent.auth_page)
            self.stack.setCurrentWidget(self.user_page)  # Сбрасываем внутренний стек
        else:
            QMessageBox.warning(self, "Ошибка", "Родительское окно не найдено")

    def load_partners(self):
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                query = """
                    SELECT p.id, p.название_компании, p.инн, p.рейтинг, 
                           SUM(hp.кол_во) as total_quantity
                    FROM партнеры p 
                    LEFT JOIN история_продаж hp ON p.id = hp.id_парнер
                    GROUP BY p.id, p.название_компании, p.инн, p.рейтинг
                """
                cursor.execute(query)
                partners = cursor.fetchall()

                self.partner_table.setRowCount(len(partners))
                for row, partner in enumerate(partners):
                    partner_id = partner["id"]
                    total_qty = partner["total_quantity"] if partner["total_quantity"] else 0

                    cursor.execute("CALL CalculatePartnerDiscount(%s, @discount)", (partner_id,))
                    cursor.execute("SELECT @discount AS discount")
                    discount = cursor.fetchone()["discount"]

                    self.partner_table.setItem(row, 0, QTableWidgetItem(str(partner_id)))
                    self.partner_table.setItem(row, 1, QTableWidgetItem(partner["название_компании"]))
                    self.partner_table.setItem(row, 2, QTableWidgetItem(partner["инн"]))
                    self.partner_table.setItem(row, 3, QTableWidgetItem(str(partner["рейтинг"])))
                    self.partner_table.setItem(row, 4, QTableWidgetItem(f"{discount}%"))
                    self.partner_table.setItem(row, 5, QTableWidgetItem(str(total_qty)))
            self.partner_table.resizeColumnsToContents()
        except Exception as e:
            QMessageBox.critical(self, "Ошибка загрузки", f"Не удалось загрузить список партнеров: {str(e)}")
        finally:
            connection.close()

    def show_partner_history(self, row, column):
        partner_id = int(self.partner_table.item(row, 0).text())
        history_dialog = PartnerHistoryDialog(self, partner_id)
        self.stack.addWidget(history_dialog)
        self.stack.setCurrentWidget(history_dialog)