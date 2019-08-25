#!/bin/bash

#*********************************************************
# check sign property of member project
# process:
# 1.find encrypt keyword in jsp, save all properties
# 2.search action name in xml file,get sign name
# 3.search sign name in xml, get sign properties
# 4.compare @3 and @1,if @3's properties appear 
#   in the @1's properties collection,it is ok,otherwise
#   we should check mannually
#
# @author zhanghao
# @groupId:dev2
# @version 1.0
# @date 20190822
#*********************************************************

# grep
# (?s) activate PCRE_DOTALL, which means that . finds any character or newline
# l:files-with-matches
# z:a data line ends in 0 byte, not newline.
# o:show only the part of a line matching PATTERN.
# a:Process a binary file as if it were text;
# n:line number
# w:word match exactly
# .*? nongreedy match

# sed
# r: extend regex
# n: slient
# i: edit files in place

# awk
# NR: line number
# $0: whole line

ls | grep -q "WebContent"
if [[ $? != 0 ]]; then 
    echo "script should be put into same level of WebContent"
    return 1
fi
if [[ ! -d check ]]; then
    mkdir check
fi;

LANG=C
rm -rf check/*

# table,fold linke, multi action
# checkList="webContent/clientReg/Mb00014_edit_company.jsp
# WebContent/abandonExecute/Mb01491_input.jsp
# WebContent/monthRpt/Mb01611_result.jsp"

# backtracking
# checkList="webContent/hedgeOptimize/Mb01792_result.jsp
# webContent/optExecStyle/Mb01461_input.jsp"

checkList=$(find . -name "*.jsp" | xargs grep -li "encrypt")
let total=0
let error=0
let success=0
starttime=$(date +'%Y-%m-%d %H:%M:%S')
startsecond=$(date --date="$starttime" +%s)
echo "${starttime}" >> check/log
for jsp in ${checkList}
do
    let total+=1
    # 1.delete chinese character
    # 2.search <form></form> and its children with single line(-z)
    # 3.delete blank line
    # .*? means nongreedy
    sed -r "s/[\x81-\xFE][\x40-\xFE]//g" ${jsp} | grep -Pzo "(?s)(\s)*<form.*?>.*?<input.*?action.*?>.*?<input.*?encrypt.*?>.*?</form>" | \
        sed -r '/^$/d' > check/form
    # start=$(awk 'NR==1{print $0}' check/table);end=$(awk 'END{print $0}' check/table)

    # jsp code style is messy,it's annoy.
    # 1.search action key word
    # 2.delete " and space
    # 3.get value of action tag
    grep -aPwo "action\"\s+value=\".*?\"" check/form | sed -r 's/"| //g' | awk -F'=' '{print $2}' > check/action

    cat check/form | while read line
    do
        # 1.search <input or <select or <textarea tag
        # 2.delete line include button or encrypt or action 
        # 3.search including name=xx
        # 4.delete "
        # 5.get field according to name=field pattern
        field=$(echo $line | grep -Pai "<(input|select|textarea).*?name(\s)*=(\s)*" | grep -Pv "button|encrypt|action" | \
            grep -Po 'name=".*?"' | sed -r 's/"//g' | awk -F'=' '{print $2}')
        if [[ ${field} != "" ]]; then
            # filed have two format.one is xxxx.field,the other is field
            echo $field | grep -P "\." > /dev/null
            if [[ $? == 0 ]]; then
                echo ${field} | awk -F'.' '{print $2}' >> check/jsp_fields
            else
                echo ${field} >> check/jsp_fields
            fi
        fi
    done
    #<input type="hidden" name="action" value="Mb01611_del" />
    # there could be multiple acton in one jsp file
    for action in $(cat check/action)
    do
        # 1.search xml and delete chinese characters
        # 2.search file with Action=${action} and formatsignid keywords
        # 3.get sign variable
        sign=$(find ./src/issConfig/action -name "*.xml" | xargs sed -r "s/[\x81-\xFE][\x40-\xFE]//g" | \
            grep -Pzo "(?s)<Action(\s)*?id(\s)*?=(\s)*?\"${action}\">.*?formatsignid.*?</Action>" | grep -aw "formatsignid" | \
            awk -F'<|>' '{print $3'})

        # 1.search xml and delete chinese characters
        # 2.search file with <FormatDef id=xxx></FormatDef> keyword
        # 3.search <Property keyword
        # 4.delete "
        # 5.get fields collection that should be signed
        checkFields=$(find ./src/issConfig/format -name "*.xml" | xargs sed -r "s/[\x81-\xFE][\x40-\xFE]//g" | \
            grep -Pzo "(?s)<FormatDef(\s)*?id(\s)*?=(\s)*?\"${sign}\".*?</FormatDef>" | grep -awi "<Property" | \
            sed -r "s/\"//g" | awk -F'=' '{print $2}' | awk '{print $1'})

        echo -e "\n[info] check \033[34mjsp:${jsp##*/} action:${action} sign:${sign} num:${total}\033[0m" | tee -a check/log
        if [[ ${checkFields} == "" ]]; then
            echo -e "[warning] can't find any property in xml file \033[34m(jsp:${jsp##*/} sign:${sign})\033[0m" | tee -a check/log
            echo "[info] check ${jsp##*/} sign property finished" | tee -a check/log
            continue 
        fi

        counts=$(echo "${checkFields}" | wc -l)
        echo -e "[info] xml fields counts:\033[34m${counts}\033[0m" | tee -a check/log
        for ((k=1;k<=counts;k+=1))
        do
            property=$(echo "${checkFields}" | sed -n "${k}p")
            if [[ ${property} == "" ]]; then
                echo -e "[error] parse xml property \033[34mfailed\033[0m" | tee -a check/log
                error=1
                continue 
            fi
            grep -awq ${property} check/jsp_fields
            if [[ $? != 0 ]]; then
                echo -e "[error] check sign property:${property} \033[34mfailed (jsp:${jsp##*/} action:${action} sign:${sign})\033[0m" | tee -a check/log
                error=1
                continue
            else
                echo -e "[info] check sign property:${property} \033[34mpassed\033[0m" | tee -a check/log
            fi
        done
        # mutlti action output in one jsp 
        echo -e "[info] check ${jsp##*/} sign property \033[34mfinished\033[0m" | tee -a check/log
    done
    # jsp check statistic
    if [[ ${error} == 0 ]]; then
        let success+=1
    else
        let error=0
    fi
done
endtime=$(date +'%Y-%m-%d %H:%M:%S')
endsecond=$(date --date="$endtime" +%s)
echo -e "\n${endtime}" >> check/log
elapse=$(($endsecond-$startsecond))
if [[ ${elapse} < $((24*60*60)) ]]; then
    hour=$(($elapse/3600))
    min=$(($elapse%3600/60))
    sec=$(($elapse-$hour*3600-$min*60))
    echo -e "\033[31mcheck ${total} files, ${success} passed, elapse time:${hour}hour ${min}m ${sec}s, \
please use 'grep error check/log' command to see error detail info.\033[0m" | tee -a check/log
else
    echo -e "\033[31mcheck ${total} files, ${success} passed, elapse time:${elapse}s, \
please use 'grep error check/log' command to see error detail info.\033[0m" | tee -a check/log
fi