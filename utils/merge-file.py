import argparse

def merge_file(file_1, file_2, file_3,stride,out_file,type):
    file_content_1 = [] 
    file_content_2 = []
    file_content_3 = []

    with open(file_1,"r",encoding="utf-8") as fp1:
        file_content_1 = fp1.readlines()
        fp1.close()

    with open(file_2,"r",encoding="utf-8") as fp2:
        file_content_2 = fp2.readlines()
        fp2.close()

    with open(file_3,"r",encoding="utf-8") as fp3:
        file_content_3 = fp3.readlines()
        fp3.close()

    if len(file_content_1) != len(file_content_2):
        print("2 files have not the same size")
        exit()
    
    with open(out_file,"a",encoding="utf-8") as fp:
        if type == "sentence":
            for i in range(len(file_content_1)):
                fp.write(file_content_1[i])
                fp.write(file_content_2[i])
                for j in range(stride):
                    fp.write(file_content_3[i+stride])
        if type == "all":
            fp.write(file_content_1)
            fp.write(file_content_2)
            fp.write(file_content_3)
        fp.close()

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='ソースファイルを作る')
    parser.add_argument("-s1", "--source_1",help="ファイル名を入力してください")
    parser.add_argument("-s2", "--source_2",help="ファイル名を入力してください")
    parser.add_argument("-s3", "--source_3",help="ファイル名を入力してください")
    parser.add_argument("-msrc", "--merge_source", help="生成ファイル名")

    parser.add_argument("-t1", "--target_1",help="ファイル名を入力してください")
    parser.add_argument("-t2", "--target_2",help="ファイル名を入力してください")
    parser.add_argument("-t3", "--target_3",help="ファイル名を入力してください")
    parser.add_argument("-mtgt", "--merge_target", help="生成ファイル名")

    parser.add_argument("-t", "--type",help='"all" or "sentence"')
    parser.add_argument("-stride", "--stride",help='stride')

    args = parser.parse_args() 

    merge_file(args.source_1, args.source_2, args.source_3, int(args.stride), args.merge_source,args.type)
    merge_file(args.target_1, args.target_2, args.target_3, int(args.stride), args.merge_target,args.type)