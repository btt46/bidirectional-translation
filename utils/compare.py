import argparse

def compareFile(file_1,file_2,output_file):
    file_content_1 = [] 
    file_content_2 = []

    with open(file_1,"r",encoding="utf-8") as fp1:
        file_content_1 = fp1.readlines()
        fp1.close()

    with open(file_2,"r",encoding="utf-8") as fp2:
        file_content_2 = fp2.readlines()
        fp2.close()


    if len(file_content_1) != len(file_content_2):
        print("2 files have not the same size")
        exit()

    lines = len(file_content_1)

    count = 0
    for i in range(lines):
        if file_content_1[i] == file_content_2[i]:
            count += 1

    with open(output_file,"w",encoding="utf-8") as fp:
        fp.write("Accuracy: ",100 * count / lines," (%)")
        fp.close()
	    
    

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='ソースファイルを作る')
    parser.add_argument("-f1", "--file_1",help="ファイル名を入力してください")
    parser.add_argument("-f2", "--file_2",help="ファイル名を入力してください")
    parser.add_argument("-o", "--output_file",help="ファイル名を入力してください")
	
    args = parser.parse_args() 

    compareFile(args.file_1, args.file_2, args.output_file)