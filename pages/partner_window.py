from PyQt6.QtWidgets import QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QTableWidget, QTableWidgetItem, QPushButton, QMessageBox, QStackedWidget, QLabel
from PyQt6.QtGui import QIcon, QPixmap
from PyQt6.QtCore import Qt
from db import get_bd_connection
from partner_dialog import PartnerDialog
from history_dialog import PartnerHistoryDialog

class PartnerWindow(QMainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent = parent
        self.setWindowTitle("Работа с партнерами - Мастер Пол")
        self.setGeometry(500, 500, 500, 500)
        self.setWindowIcon(QIcon("Мастер пол.png"))
        self.setStyleSheet("background-color: #FFFFFF; font-family: Segoe UI;")

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.stack = QStackedWidget()
        layout = QVBoxLayout(self.central_widget)
        layout.addWidget(self.stack)

        self.partner_page = QWidget()
        self.init_partner_page()
        self.stack.addWidget(self.partner_page)

        self.load_partners()

    def init_partner_page(self):
        layout = QVBoxLayout(self.partner_page)

        logo_label = QLabel()
        logo_pixmap = QPixmap("Мастер пол.png")
        logo_label.setPixmap(logo_pixmap.scaled(150, 50, Qt.AspectRatioMode.KeepAspectRatio))
        layout.addWidget(logo_label, alignment=Qt.AlignmentFlag.AlignCenter)

        self.partner_table = QTableWidget()
        self.partner_table.setColumnCount(6)
        self.partner_table.setHorizontalHeaderLabels(["ID", "Название", "ИНН", "Рейтинг", "Скидка", "Объем продаж"])
        self.partner_table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.partner_table.cellDoubleClicked.connect(self.show_partner_history)
        self.partner_table.cellClicked.connect(self.enable_edit)
        layout.addWidget(self.partner_table)

        button_layout = QHBoxLayout()
        self.add_button = QPushButton("Добавить партнера")
        self.edit_button = QPushButton("Редактировать партнера")
        calc_button = QPushButton("Рассчитать материал")
        refresh_button = QPushButton("Обновить")
        back_button = QPushButton("Назад")
        self.add_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        self.edit_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        calc_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        refresh_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        back_button.setStyleSheet("background-color: #D9534F; color: white; padding: 5px;")
        self.edit_button.setEnabled(False)
        self.add_button.clicked.connect(self.add_partner)
        self.edit_button.clicked.connect(self.edit_partner)
        calc_button.clicked.connect(self.calculate_material)
        refresh_button.clicked.connect(self.load_partners)
        back_button.clicked.connect(self.go_back)
        button_layout.addWidget(self.add_button)
        button_layout.addWidget(self.edit_button)
        button_layout.addWidget(calc_button)
        button_layout.addWidget(refresh_button)
        button_layout.addWidget(back_button)
        layout.addLayout(button_layout)

    def go_back(self):
        if self.parent:
            self.parent.stack.setCurrentWidget(self.parent.auth_page)
            self.stack.setCurrentWidget(self.partner_page)  # Сбрасываем внутренний стек
        else:
            QMessageBox.warning(self, "Ошибка", "Родительское окно не найдено")

    def enable_edit(self, row, column):
        self.edit_button.setEnabled(True)

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

    def add_partner(self):
        dialog = PartnerDialog(self, None)
        self.stack.addWidget(dialog)
        self.stack.setCurrentWidget(dialog)
        dialog.destroyed.connect(lambda: self.stack.removeWidget(dialog))
        dialog.destroyed.connect(self.load_partners)

    def edit_partner(self):
        selected_row = self.partner_table.currentRow()
        if selected_row == -1:
            QMessageBox.warning(self, "Предупреждение", "Выберите партнера для редактирования.")
            return
        partner_id = int(self.partner_table.item(selected_row, 0).text())
        dialog = PartnerDialog(self, partner_id)
        self.stack.addWidget(dialog)
        self.stack.setCurrentWidget(dialog)
        dialog.destroyed.connect(lambda: self.stack.removeWidget(dialog))
        dialog.destroyed.connect(self.load_partners)

    def show_partner_history(self, row, column):
        partner_id = int(self.partner_table.item(row, 0).text())
        history_dialog = PartnerHistoryDialog(self, partner_id)
        self.stack.addWidget(history_dialog)
        self.stack.setCurrentWidget(history_dialog)

    def calculate_material(self):
        selected_row = self.partner_table.currentRow()
        if selected_row == -1:
            QMessageBox.warning(self, "Предупреждение", "Выберите партнера для расчета материала.")
            return
        partner_id = int(self.partner_table.item(selected_row, 0).text())
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT hp.id_продукция, hp.кол_во
                    FROM история_продаж hp
                    WHERE hp.id_парнер = %s
                    ORDER BY hp.дата DESC LIMIT 1
                """, (partner_id,))
                sale = cursor.fetchone()
                if not sale:
                    QMessageBox.warning(self, "Ошибка", "У партнера нет истории продаж.")
                    return
                product_id = sale["id_продукция"]
                product_quantity = sale["кол_во"]

                cursor.execute("""
                    SELECT p.id_тип_продукции, p.длина, p.ширина, m.id_тип_материала
                    FROM продукция p
                    JOIN материал m ON p.id_материал = m.id
                    WHERE p.id = %s
                """, (product_id,))
                product = cursor.fetchone()
                if not product:
                    QMessageBox.warning(self, "Ошибка", "Не удалось найти данные о продукции или материале.")
                    return

                product_type_id = product["id_тип_продукции"]
                material_type_id = product["id_тип_материала"]
                param1 = product["длина"]
                param2 = product["ширина"]

                cursor.execute("SELECT CalculateMaterialQuantity(%s, %s, %s, %s, %s) AS result",
                               (product_type_id, material_type_id, product_quantity, param1, param2))
                result = cursor.fetchone()["result"]
                if result == -1:
                    QMessageBox.warning(self, "Ошибка расчета", "Неверные параметры для расчета материала.")
                else:
                    QMessageBox.information(self, "Результат", f"Необходимое количество материала: {result}")
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось выполнить расчет: {str(e)}")
        finally:
            connection.close()