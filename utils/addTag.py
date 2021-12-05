import argparse

def addTag(file_name,p1,p2,tag_1,tag_2):
	file_content = []
	addTag_content = []
	count = 1;

	with open(file_name,"r",encoding="utf-8") as fp:
		file_content = fp.readlines()
		fp.close()

	for line in file_content:
		if (count <= p1):
			addTag_content.append(tag_1 + " " + line)
		if (count > p1 and count <= p2):
			addTag_content.append(tag_2 + " " + line)
		count += 1
		if (count > p2): 
			count = 1

	with open(file_name,"w",encoding="utf-8") as fp:
		fp.writelines(addTag_content)
		fp.close()

if __name__=="__main__":
	parser = argparse.ArgumentParser(description='ソースファイルを作る')
	parser.add_argument("-f", "--file_name",help="ファイル名を入力してください")
	parser.add_argument("-p1", "--position_1",help="ファイル名を入力してください")
	parser.add_argument("-t1", "--tag_1",help="ファイル名を入力してください")
	parser.add_argument("-p2", "--position_2",help="ファイル名を入力してください")
	parser.add_argument("-t2", "--tag_2",help="ファイル名を入力してください")

	args = parser.parse_args() 

	addTag(args.file_name, int(args.position_1), int(args.position_2),args.tag_1, args.tag_2)