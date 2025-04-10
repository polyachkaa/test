from PyQt6.QtWidgets import QApplication
from login_dialog import LoginDialog
import sys

if __name__ == "__main__":
    app = QApplication(sys.argv)
    login_dialog = LoginDialog()
    login_dialog.show()
    sys.exit(app.exec())



































































