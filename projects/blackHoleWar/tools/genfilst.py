#coding:utf-8
import os
import os.path
import hashlib
import sys

#计算文件的md5值
def calfilemd5(file): 
 	md5 = hashlib.md5()
 	fs = open(file, 'rb')
 	while True:#--小文件就没必要这样分段计算了
 		buf = fs.read(1024)
 		if buf:
 			md5.update(buf)
 		else:
 			break
 	return md5.hexdigest()				

#计算文件的size
def calfilesize(file):
	return os.path.getsize(file)

#遍历文件夹并生成flist文件
def genflist(root_dir):
	flist = "local flist = {\n" +\
	"	appVersion = 1,\n" +\
	"	version = \"1.0.1\",\n" +\
	"	dirPaths = {\n"
	
	#提取所有目录的路径
	for dirpath , dirnames, filenames in os.walk(root_dir):
		if root_dir != dirpath:
			flist = flist + "		{name = \"" + dirpath.replace((root_dir + '\\'),'') + "\"},\n"
	flist = flist + "\n 	},\n 	fileInfoList={\n"
	#计算所有文件的size和md5
	for dirpath , dirnames, filenames in os.walk(root_dir):
		f_dir = dirpath.replace((root_dir + '\\'),'')
		for f in filenames:
			f_md5 = calfilemd5(os.path.join(dirpath,f))
			f_size = calfilesize(os.path.join(dirpath,f))
			last_dir = ''
			if root_dir != f_dir:
				last_dir = f_dir + '\\' + f
			else:
				last_dir = f
			flist = flist + "		{name = \"" + last_dir + "\",md5 = \"" + str(f_md5) + "\",size = " + str(f_size) + "},\n"
	flist = flist + "	},\n}"
	filehandle = open('flist.lua','w')
	filehandle.write(flist)
	filehandle.close()	
if __name__ == '__main__' :
	root_dir = sys.argv[1]
	genflist(root_dir)