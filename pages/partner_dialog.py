from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QFormLayout, QLineEdit, QPushButton, QComboBox, QMessageBox
from db import get_bd_connection

class PartnerDialog(QWidget):
    def __init__(self, parent=None, partner_id=None):
        super().__init__(parent)
        self.parent = parent
        self.partner_id = partner_id
        self.setWindowTitle("Добавить/Редактировать партнера - Мастер Пол")
        self.setStyleSheet("background-color: #F4E8D3; font-family: Segoe UI;")

        layout = QVBoxLayout(self)

        form_layout = QFormLayout()
        self.company_name = QLineEdit()
        self.legal_address = QLineEdit()
        self.inn = QLineEdit()
        self.last_name = QLineEdit()
        self.first_name = QLineEdit()
        self.middle_name = QLineEdit()
        self.phone = QLineEdit()
        self.email = QLineEdit()
        self.rating = QLineEdit()
        self.rating.setPlaceholderText("Введите целое неотрицательное число")
        self.partner_type = QComboBox()

        form_layout.addRow("Название компании:", self.company_name)
        form_layout.addRow("Юр. адрес:", self.legal_address)
        form_layout.addRow("ИНН:", self.inn)
        form_layout.addRow("Фамилия директора:", self.last_name)
        form_layout.addRow("Имя директора:", self.first_name)
        form_layout.addRow("Отчество директора:", self.middle_name)
        form_layout.addRow("Телефон:", self.phone)
        form_layout.addRow("Email:", self.email)
        form_layout.addRow("Рейтинг:", self.rating)
        form_layout.addRow("Тип партнера:", self.partner_type)
        layout.addLayout(form_layout)

        button_layout = QHBoxLayout()
        save_button = QPushButton("Сохранить")
        back_button = QPushButton("Назад")
        save_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        back_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        save_button.clicked.connect(self.save_partner)
        back_button.clicked.connect(self.go_back)
        button_layout.addWidget(save_button)
        button_layout.addWidget(back_button)
        layout.addLayout(button_layout)

        self.load_partner_types()
        if partner_id:
            self.load_partner_data()

    def load_partner_types(self):
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                query = "SELECT id, название FROM тип_партнера"
                cursor.execute(query)
                types = cursor.fetchall()
                for type_data in types:
                    self.partner_type.addItem(type_data["название"], type_data["id"])
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось загрузить типы партнеров: {str(e)}")
        finally:
            connection.close()

    def load_partner_data(self):
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                query = "SELECT * FROM партнеры WHERE id = %s"
                cursor.execute(query, (self.partner_id,))
                partner = cursor.fetchone()
                if partner:
                    self.company_name.setText(partner["название_компании"])
                    self.legal_address.setText(partner["юр_адрес"])
                    self.inn.setText(partner["инн"])
                    self.last_name.setText(partner["фамилия"])
                    self.first_name.setText(partner["имя"])
                    self.middle_name.setText(partner["отчество"])
                    self.phone.setText(partner["телефон"])
                    self.email.setText(partner["почта"])
                    self.rating.setText(str(partner["рейтинг"]))
                    index = self.partner_type.findData(partner["id_тип_партнера"])
                    if index >= 0:
                        self.partner_type.setCurrentIndex(index)
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось загрузить данные партнера: {str(e)}")
        finally:
            connection.close()

    def save_partner(self):
        try:
            rating_text = self.rating.text()
            if not rating_text.isdigit() or int(rating_text) < 0:
                QMessageBox.warning(self, "Ошибка ввода",
                                    "Рейтинг должен быть целым неотрицательным числом.\nВведите корректное значение.")
                return
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                partner_type_id = self.partner_type.currentData()
                if self.partner_id:
                    query = """
                        UPDATE партнеры SET название_компании=%s, юр_адрес=%s, инн=%s, фамилия=%s, имя=%s, 
                        отчество=%s, телефон=%s, почта=%s, рейтинг=%s, id_тип_партнера=%s
                        WHERE id=%s
                    """
                    cursor.execute(query, (
                        self.company_name.text(), self.legal_address.text(), self.inn.text(),
                        self.last_name.text(), self.first_name.text(), self.middle_name.text(),
                        self.phone.text(), self.email.text(), int(rating_text),
                        partner_type_id, self.partner_id
                    ))
                    action = "обновлены"
                else:
                    query = """
                        INSERT INTO партнеры (название_компании, юр_адрес, инн, фамилия, имя, отчество, 
                        телефон, почта, рейтинг, id_тип_партнера)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """
                    cursor.execute(query, (
                        self.company_name.text(), self.legal_address.text(), self.inn.text(),
                        self.last_name.text(), self.first_name.text(), self.middle_name.text(),
                        self.phone.text(), self.email.text(), int(rating_text),
                        partner_type_id
                    ))
                    action = "добавлены"
                connection.commit()
            QMessageBox.information(self, "Успех", f"Данные партнера успешно {action}.")
            self.parent.load_partners()
            self.go_back()
        except ValueError as ve:
            QMessageBox.critical(self, "Ошибка ввода",
                                 f"Некорректный формат данных: {str(ve)}\nПроверьте введенные значения.")
        except Exception as e:
            QMessageBox.critical(self, "Ошибка сохранения",
                                 f"Не удалось сохранить данные: {str(e)}\nПроверьте подключение к базе данных.")
        finally:
            connection.close()

    def go_back(self):
        self.parent.stack.setCurrentWidget(self.parent.partner_page)