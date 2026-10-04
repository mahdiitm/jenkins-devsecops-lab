import subprocess

user_input = input("Enter a command: ")
subprocess.call(user_input, shell=True)
