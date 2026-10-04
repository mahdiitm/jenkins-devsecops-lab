import subprocess

user_input = input("Enter a program: ")
subprocess.run([user_input], shell=False)
