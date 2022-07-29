#!/bin/bash


# Ideas to use the tree
# --------------------------------------
# 1. dependency tree -- what kind?
#
# Task -> Dependent Task
#
#
# 2. topological sort

# How to represent a tree in bash

# struct tree {          # Singleton
#   int count            # fundamental for travercing the structure
#   int[] nodeindices    # count tells us how many indices to jump to get past this
#   node[] nodes         # beware, nodes vary in size
# }

# struct node {
#   int childcount       # fundamental for knowing where structure ends
#   int[] childindices   # children must be within tree
# }
debug="$1"

if [ "$debug" == "debug" ]
then
  function trace() {
    echo " > $@" 1>&2
  }
else
  function trace() {
    [ true ] # empty function
  }
fi

# Store all nodes in a single array
nodes=(0)

function clear_nodes() {
  nodes=(0)
}

function count_nodes() { # -> int count
  echo ${nodes[0]}
}

function append_node() { # -> int node index
  trace "append_node"

  let newNodeIndex=`count_nodes`
  nodes+=(0)
  local -i newNodePos=${#nodes[@]}        # Position of node header after a shift
  let nodes[0]++                          # Increment count_nodes
  local -i newNodeIndexRefPos=${nodes[0]} # Happens to be the exact location we need
  shift $newNodeIndexRefPos               # Making room for new node index
  nodes[$newNodeIndexRefPos]=$newNodePos

  echo $newNodeIndex                      # return
}

function find_node () { # -> int raw index
  trace "find_node $1" >> /dev/null
  [ count_nodes == 0 ] && echo "No nodes to find" 1>&2 exit 01
  local -i i=$1         # 0 indexed
  local -i ip1=i+1      # skipping count
  echo ${nodes[$ip1]}   # pulling value from nodeindices array
}

function append_child() {
  trace "append_child $1 $2"
  local -i parentindex=$1        # 0 indexed
  local -i childindex=$2         # 0 indexed; child is already added to tree
  local -i nodecount=`count_nodes`
  local -i parentPos=`find_node $parentindex`
  
  trace appending child to node starting at $parentPos
  let nodes[$parentPos]++   # increase node's childcount
  if [ $((nodecount + 1)) -eq $parentindex ] 
  then                      # -- the end of the raw array -- #
    nodes+=($childindex)    # the node substructure's childindices are at end, and the meta structure has no meta data at the end
  else                      # -- in the middle of the raw array -- #
    local -i childindexpos=$parentPos+${nodes[$parentPos]}
    shift $childindexpos    # since we're adding an element in the middle of the structure we need to shift everything right
    let nodes[$childindexpos]=childindex
  fi
}

function add_parent() {
  trace "add_parent $1 $2"
  append_child $2 $1
}

function get_child_indices() { # int[] node indices
  trace "get_child_indices $1"
  local -i parentindex=$1
  local -i parentPos=`find_node $parentindex`
  local -i childcount=${nodes[$parentPos]} # childcount is first index of a node struct

  trace looking for parent at index $parentindex which was found at $parentPos

  local i=1                    # 1 indexed to make childPos calculation easier
  while [ $i -le $childcount ] # seq 1 $childcount
  do
    local -i childPos=i+parentPos
    echo x $i at $childPos x 1>&2
    echo ${nodes[$childPos]}   # yeild return 
    local -i i=$((i+1))
  done
}

function shift() {
  trace "shift $1"
  local -i pos=$1         # pure shell array index
  # -- Assertions -- #
  [ $pos -le 0 ] && echo "cannot shift count location" 1>&2 && exit 13
  # ---------------- #
  local -i indexstart=1
  effectedNodes=()
  firstEffectedNodeIndex=
  for i in `seq 0 $((nodes[0] - 1))`
  do
    if [ $(( nodes[i + 1] )) -ge $pos ] 
    then
      let nodes[$((i+1))]++ # incrementing node index to reflect shift in referenced values location
    fi
  done

  local -i nodearraystart=${nodes[0]+1} 
  local -i i=${#nodes[@]}    # count
  local -i im1=i-1           # last index
  while [ $i -gt $pos ]      # seq $lastindex -1 $1
  do
    let nodes[$i]=${nodes[$im1]} # x[n] = x[n-1]
    local -i i=im1   # == i--
    local -i im1=i-1 # == im1--
  done
}

function calculate_costs() {
  local costs=
  local 
  for i in $( seq 1 $( count_nodes ) )
  do
    costs+=( 0 )
    # dfs to find cost
    echo $i
  done
  echo ${costs[@]}


}

# -- tests -- #

# 0
echo ${nodes[*]}
[ `count_nodes` != 0 ] && echo "!! Count is off `count_nodes`. Expected 0" 1>&2 && exit 21 

append_node
# 1 2 0
echo ${nodes[*]}
[ `find_node 0` != 2 ] && echo "!! first node found incorrectly " 1>&2 && exit 22
[ `count_nodes` != 1 ] && echo "!! Count is off `count_nodes`. Expected 1" 1>&2 && exit 21 

append_node
# 2 3 4 0 0
echo ${nodes[*]}
echo Found second node at position `find_node 1`
[ `find_node 0` != 3 ] && echo "!! first node found incorrectly `find_node 0` expected 3 " 1>&2 && exit 22
[ `find_node 1` != 4 ] && echo "!! second node found incorrectly `find_node 1` expected 4" 1>&2 && exit 22
[ `count_nodes` != 2 ] && echo "!! Count is off `count_nodes`. Expected 2" 1>&2 && exit 21 

append_child 1 0
# 2 3 4 0 1 0
echo ${nodes[*]}
[ `find_node 0` != 3 ] && echo "!! first node found incorrectly `find_node 0` expected 3 " 1>&2 && exit 22 
[ `find_node 1` != 4 ] && echo "!! second node found incorrectly `find_node 1` expected 4" 1>&2 && exit 22
[ `count_nodes` != 2 ] && echo "!! Count is off `count_nodes`. Expected 2" 1>&2 && exit 21 

append_node
# 3 4 5 7 0 1 0 0
echo ${nodes[*]}
[ `find_node 0` != 4 ] && echo "!! first node found incorrectly `find_node 0` expected 4 " 1>&2 && exit 22 
[ `find_node 1` != 5 ] && echo "!! second node found incorrectly `find_node 1` expected 5" 1>&2 && exit 22
[ `find_node 2` != 7 ] && echo "!! second node found incorrectly `find_node 2` expected 7" 1>&2 && exit 22
[ `count_nodes` != 3 ] && echo "!! Count is off `count_nodes`. Expected 3" 1>&2 && exit 21 

append_node
# 4 5 6 8 9 0 1 0 0 0
echo ${nodes[*]}
[ `find_node 0` != 5 ] && echo "!! first node found incorrectly `find_node 0` expected 5 " 1>&2 && exit 22 
[ `find_node 1` != 6 ] && echo "!! second node found incorrectly `find_node 1` expected 6" 1>&2 && exit 22
[ `find_node 2` != 8 ] && echo "!! second node found incorrectly `find_node 2` expected 8" 1>&2 && exit 22
[ `find_node 3` != 9 ] && echo "!! second node found incorrectly `find_node 3` expected 9" 1>&2 && exit 22
[ `count_nodes` != 4 ] && echo "!! Count is off `count_nodes`. Expected 4" 1>&2 && exit 21 

append_child 0 2
# 4 5 7 9 10 1 2 1 0 0 0
echo ${nodes[*]}
[ `find_node 0` != 5 ] && echo "!! first node found incorrectly `find_node 0` expected 5 " 1>&2 && exit 22 
[ `find_node 1` != 7 ] && echo "!! second node found incorrectly `find_node 1` expected 7" 1>&2 && exit 22
[ `find_node 2` != 9 ] && echo "!! second node found incorrectly `find_node 2` expected 9" 1>&2 && exit 22
[ `find_node 3` != 10 ] && echo "!! second node found incorrectly `find_node 3` expected 10" 1>&2 && exit 22
[ `count_nodes` != 4 ] && echo "!! Count is off `count_nodes`. Expected 4" 1>&2 && exit 21 

append_child 0 3
# 4 5 8 10 11 2 2 3 1 0 0 0
echo ${nodes[*]}
[ `find_node 0` != 5 ] && echo "!! first node found incorrectly `find_node 0` expected 5 " 1>&2 && exit 22 
[ `find_node 1` != 8 ] && echo "!! second node found incorrectly `find_node 1` expected 8" 1>&2 && exit 22
[ `find_node 2` != 10 ] && echo "!! second node found incorrectly `find_node 2` expected 10" 1>&2 && exit 22
[ `find_node 3` != 11 ] && echo "!! second node found incorrectly `find_node 3` expected 11" 1>&2 && exit 22
[ `count_nodes` != 4 ] && echo "!! Count is off `count_nodes`. Expected 4" 1>&2 && exit 21 

echo "q: from 0 get children" `get_child_indices 0`
echo q: from 1 get children `get_child_indices 1`
echo q: from 2 get children `get_child_indices 2`

calculate_costs

