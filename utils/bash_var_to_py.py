import os;
import subprocess;

def bash_var_to_py(scriptname, varname):

    cmd = ['. {}; echo ${}'.format(scriptname, varname)];
    #print "cmd: ", cmd;
    assert(os.path.isfile(scriptname)); 

    res = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE);
    out = res.communicate();
    return out[0].strip();


# if __name__ == "__main__":
#     scriptname = "./data_utils_init.sh";
#     varname = "S3_HOST_DIR";

#     val = bash_var_to_py(scriptname, varname);
#     print "script: ", scriptname;
#     print "{}: {}".format(varname, val);

    
