
unset dstack
unset istack
dBP=100
dSP=$dBP
declare -a dstack
dpush () {
    test -z "$1" && return
    let "dSP -= 1"
    dstack[$dSP]=$1
}
dpop () {
    test "$dSP" -eq "$dBP" && return
    let "dSP += 1"
    dData=${dstack[$dSP]}
}

    
iBP=100
iSP=$iBP
declare -a istack
ipush () {
    test -z "$1" && return
    let "iSP -= 1"
    istack[$iSP]=$1
}
ipop () {
    test "$SP" -eq "$iBP" && return
    let "SP += 1"
    iData=${stack[$SP]}
}




renci_ci_asciidir () {
    rootdir=$1
    excludes=".svn"
    local tab="    "
    local base=
    local dir=
    local dirs=
    local last_base=
    local last_dir=
    local indent=
    local old_indent=
    local old_dir=$rootdir
    echo $( basename $rootdir)
    for file in `find $rootdir | grep -v .svn | sed -e "s,^\.,," -e "s,^/,,"`; do
	if [ "$( echo ${file} | grep -c ${excludes} )" -gt 0 ]; then	    
	    continue
	elif [ -z "$file" ]; then
	    continue
	else
	    dir=$( dirname $file | sed "s,\.,,")
	    if [ -z "${dir}" ]; then
		dir=${file}
	    fi
	    base=$( basename $file )
	    if [ -d "${file}" ]; then
dir=${file}
for d in ${dstack[@]}; do
    echo "$(dirname $file)" = "${dstack[$dSP]}" 
    if [ ! "$(dirname $file)" = "${dstack[$dSP]}" ]; then
	dpop
echo popped $dData top ${dstack[$dSP]}
	ipop
    fi
done
indent=${ipop[$iSP]}
echo indent: [$indent]
for x in ${dstack[@]}; do
    echo $x
done
dpush $dir

echo old_dir: $old_dir file: $file dir: $dir dirnamefile: "$( dirname $file )" lastdir: "$last_dir"


#for c in $(seq $SP 1 $(( $BP - 1 ))); do 
#                for c in ${istack[@]}; do
#		    if [ "x$(dirname dir)" = "x$c" ]; then
#		    fi
#		done

need_indent=1

                if [ "x$( dirname $file )" = "x." ]; then
		    echo --indent
		    old_indent=${indent}
		    indent="${old_indent} ${tab}"
		    ipush $indent
		fi

		    very_old_indent=${old_indent}
		    old_indent=${indent}
#		    need_indent=1		    
		    more_of_this_dir=0
		    ready=0
		    scanning_for_new=1
		    for af in $( find $rootdir | sed "s,\./,," | grep -v ${excludes} ); do
			test "$ready" = 1 && {
			    found_one=0
			    old_dir=${stack[$(( $SP - 1 ))]}
			    if [ "$(dirname ${af})" = "$old_dir" ]; then
				more_of_this_dir=1
				break;
			    fi
			}
			if [ -z "$last_dir" ]; then
			    ready=1
			fi
			test "x$af" = "x$file" && {
			ready=1
			}
		    done
		    push $dir
		    dirs="${dirs} /$(echo ${dir} | sed s,\./,,)/"

		old_dir=$dir
	    elif [ ! -d $file ]; then
		if [ "${need_outdent}" = 1 ]; then
		    indent="${old_indent} ${tab}"
		    need_outdent=0
		fi
		if [ "${need_indent}" = 1 ]; then
		    if [ "${more_of_this_dir}" = 1 ]; then
			indent="${indent}|${tab}"
		    else
			indent="${very_old_indent} ${tab} ${tab}"
		    fi
		    need_indent=0		
		    ipush $indent
		fi
	    fi
	    printf "%s%s\n" "${indent}" "|-- ${base}"

	    last_base=${base}
	    last_dir=${dir}
	    last_file=${file}
	fi
    done
}