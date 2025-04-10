from PyQt6.QtCore import Qt
from PyQt6.QtGui import QIcon
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QMessageBox, QLabel, QComboBox, QStackedWidget, QFormLayout, QLineEdit, \
    QDialog, QPushButton
from db import get_bd_connection
from partner_window import PartnerWindow
from user_window import UserWindow


class LoginDialog(QDialog):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("МАСТЕР")
        self.setGeometry(300, 300, 300, 200)
        self.setWindowIcon(QIcon("Мастер пол.png"))
        self.setStyleSheet("background-color: #FFFFFF; font-family: Segoe UI;")

        layout = QVBoxLayout(self)
        self.stack = QStackedWidget()
        layout.addWidget(self.stack)

        # Страница авторизации
        self.auth_page = self.init_auth_page()
        self.stack.addWidget(self.auth_page)

        # Страница регистрации
        self.reg_page = self.init_reg_page()
        self.stack.addWidget(self.reg_page)

    def init_auth_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)

        logo_label = QLabel("Авторизация")
        layout.addWidget(logo_label, alignment=Qt.AlignmentFlag.AlignCenter)

        self.auth_form = QFormLayout()
        self.username = QLineEdit()
        self.password = QLineEdit()
        self.password.setEchoMode(QLineEdit.EchoMode.Password)
        self.auth_form.addRow("Логин:", self.username)
        self.auth_form.addRow("Пароль:", self.password)
        layout.addLayout(self.auth_form)

        login_button = QPushButton("Войти")
        login_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        login_button.clicked.connect(self.check_login)
        layout.addWidget(login_button)

        reg_button = QPushButton("Регистрация")
        reg_button.setStyleSheet("background-color: #4A90E2; color: white; padding: 5px;")
        reg_button.clicked.connect(lambda: self.stack.setCurrentWidget(self.reg_page))
        layout.addWidget(reg_button)

        return page

    def init_reg_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)

        logo_label = QLabel("Регистрация")
        layout.addWidget(logo_label, alignment=Qt.AlignmentFlag.AlignCenter)

        self.reg_form = QFormLayout()
        self.reg_username = QLineEdit()
        self.reg_password = QLineEdit()
        self.reg_password.setEchoMode(QLineEdit.EchoMode.Password)
        self.reg_role = QComboBox()
        self.reg_role.addItems(["Пользователь", "Админ"])
        self.reg_form.addRow("Логин:", self.reg_username)
        self.reg_form.addRow("Пароль:", self.reg_password)
        self.reg_form.addRow("Роль:", self.reg_role)
        layout.addLayout(self.reg_form)

        reg_submit_button = QPushButton("Зарегистрироваться")
        reg_submit_button.setStyleSheet("background-color: #67BA80; color: white; padding: 5px;")
        reg_submit_button.clicked.connect(self.register)
        layout.addWidget(reg_submit_button)

        back_button = QPushButton("Назад")
        back_button.setStyleSheet("background-color: #D9534F; color: white; padding: 5px;")
        back_button.clicked.connect(lambda: self.stack.setCurrentWidget(self.auth_page))
        layout.addWidget(back_button)

        return page

    def check_login(self):
        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                query = "SELECT role FROM users WHERE username = %s AND password = %s"
                cursor.execute(query, (self.username.text(), self.password.text()))
                user = cursor.fetchone()
                if user:
                    role = user["role"]
                    if role == "admin":
                        self.partner_window = PartnerWindow(self)
                        self.stack.addWidget(self.partner_window)
                        self.stack.setCurrentWidget(self.partner_window)
                    else:
                        self.user_window = UserWindow(self)
                        self.stack.addWidget(self.user_window)
                        self.stack.setCurrentWidget(self.user_window)
                else:
                    QMessageBox.critical(self, "Ошибка авторизации", "Неверный логин или пароль.")
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось подключиться к БД: {str(e)}")
        finally:
            connection.close()

    def register(self):
        username = self.reg_username.text().strip()
        password = self.reg_password.text().strip()
        role_display = self.reg_role.currentText()
        role = "user" if role_display == "Пользователь" else "admin"

        if not username or not password:
            QMessageBox.warning(self, "Ошибка", "Заполните все поля")
            return

        try:
            connection = get_bd_connection()
            with connection.cursor() as cursor:
                cursor.execute("SELECT id FROM users WHERE username = %s", (username,))
                if cursor.fetchone():
                    QMessageBox.warning(self, "Ошибка", "Пользователь с таким логином уже существует")
                    return
                query = "INSERT INTO users (username, password, role) VALUES (%s, %s, %s)"
                cursor.execute(query, (username, password, role))
                connection.commit()
            QMessageBox.information(self, "Успех", "Регистрация прошла успешно")
            self.stack.setCurrentWidget(self.auth_page)
        except Exception as e:
            QMessageBox.critical(self, "Ошибка", f"Ошибка регистрации: {str(e)}")
        finally:
            connection.close()