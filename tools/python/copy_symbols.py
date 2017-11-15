import os
import fnmatch
import shutil

omim_root = "/".join((os.path.dirname(os.path.realpath(__file__)), "../.."))
build_root = "/".join((omim_root, "android", ".externalNativeBuild", "cmake"))
target_root = "/".join((omim_root, "android", "build", "outputs", "obj"))

def copy_obj_files_to_dir(obj_dir, target_dir):
    stat = 0
    for dirpath, dirnames, files in os.walk(obj_dir):
        for obj_file in fnmatch.filter(files, '*.o'):
            obj_file_path = os.path.join(dirpath, obj_file)
            shutil.copy(obj_file_path, target_dir)
            stat += 1
    return stat

def mkdir(path):
    if not os.path.exists(path):
        os.makedirs(path)
    return path

if __name__ == "__main__":
    if os.path.isdir(build_root):
        flavours = os.listdir(build_root)
        print("Flavours are: {}".format(flavours))
        for flavour in flavours:
            abi_dir = "/".join((build_root, flavour))
            abi_list = os.listdir(abi_dir)
            print("Archs are: {}".format(abi_list))
            for abi in abi_list:
                obj_dir = "/".join((abi_dir, abi))
                target_dir = mkdir("/".join((target_root, flavour, abi)))
                stat = copy_obj_files_to_dir(obj_dir, target_dir)
                print("{} files copied for {}/{}".format(stat, flavour, abi))
    else:
        print("No symbols found")
