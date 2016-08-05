#coding:utf-8
import os
import sys
import re
import shutil
import subprocess

CUR_PY_DIR = os.path.split(os.path.realpath(__file__))[0]
PHP_DIR = os.path.join(CUR_PY_DIR,'bin\\win32\\php.exe')
PHP_COMPILE = os.path.join(CUR_PY_DIR,'bin\\lib\\compile_scripts.php')
def compile_zip(source,target):
	if not os.path.isdir(source):
		raise Exception('invalid dir path : %s' % source)
	if not os.path.isdir(os.path.dirname(target)):
		os.makedirs(os.path.dirname(target))
	dir_path = ""
	if os.path.isdir(source):
		dir_path = os.path.split(source)[1]
		subprocess.call([PHP_DIR, PHP_COMPILE, '-i', source, '-o', target, '-p', dir_path, '-m', 'zip'])
	else:
		subprocess.call([PHP_DIR, PHP_COMPILE, '-i', source, '-o', target, '-m', 'zip'])

def pack_scripts():
	lua_root = os.path.join(CUR_PY_DIR,'..\\Resources\\scripts')
	target_path = os.path.join(CUR_PY_DIR,'out')
	if os.path.isdir(target_path):
		shutil.rmtree(target_path)
	files = os.listdir(lua_root)
	for file in files:
		file_path = os.path.join(lua_root,file)
		if os.path.isdir(file_path):
			compile_zip(file_path,os.path.join(target_path, file + '.zip'))
		elif os.path.isfile(file_path) and re.match(r'(.*?)\.lua$',file):
			shutil.copy(file_path,target_path)
	build_resinfo()

def build_resinfo():
	zip_path = os.path.join(CUR_PY_DIR,'out')
	target_path = CUR_PY_DIR
	files = os.listdir(zip_path)
	for file in files:
		if re.match(r'(.*?)\.zip$',file):
			print(file)
pack_scripts()