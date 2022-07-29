#!/bin/bash


# adding int[] nodeindicies to structure
# --------------------------------------
# count_nodes:       uneffacted
# append_node:       needs testing
# find_node:         trivial but needs testing
# append_child:      uneffected but was cleaned up so needs testing
# get_child_indices: uneffected
# shift:             needs testing

# How to represent a tree in bash

# struct tree {           # Singleton
#   int count             # fundamental for travercing the structure
#   int[] nodeindicies    # count tells us how many indicies to jump to get past this
#   node[] nodes          # beware, nodes vary in size
# }

# struct node {
#   int childcount        # fundamental for knowing where structure ends
#   int[] childindicies   # children must be within tree
# }

# Store all nodes in a single array
nodes=(0)

function count_nodes(){
  echo ${nodes[0]}
}

function append_node() {
  echo " > append_node" 1>&2
  let newNodeIndex=`count_nodes`
  nodes+=(0)
  let newNodePos=${#nodes[@]}        # Position of node header after a shift
  let nodes[0]++                     # Increment count_nodes
  let newNodeIndexRefPos=${nodes[0]} # Happens to be the exact location we need
  shift $newNodeIndexRefPos          # Making room for new node index
  nodes[$newNodeIndexRefPos]=$newNodePos
}

function find_node () {
  echo " > find_node $1" 1>&2
  [ count_nodes == 0 ] && echo "No nodes to find" 1>&2 exit 01
  let i=$1            # 0 indexed
  let ip1=i+1         # skipping count
  echo ${nodes[$ip1]} # pulling value from nodeindicies array
}

function append_child() {
  echo " > append_child $1 $2" 1>&2
  let parentindex=$1                    # 0 indexed
  let childindex=$2                     # 0 indexed; child is already added to tree
  let nodecount=`count_nodes`
  let parentPos=`find_node $parentindex`
  
  echo " >" appending child to node starting at $parentPos 1>&2
  let nodes[$parentPos]++   # increase node's childcount
  if [ $((nodecount + 1)) -eq $parentindex ] 
  then                      # "the end"
    nodes+=($childindex)    # the node substructure's childindicies are at end, and the meta structure has no meta data at the end
  else                      # "in the middle"
    let childindexpos=$parentPos+${nodes[$parentPos]}
    shift $childindexpos    # since we're adding an element in the middle of the structure we need to shift everything right
    let nodes[$childindexpos]=childindex
  fi
}

function get_child_indices() {
  echo " > get_child_indices $1" 1>&2
  let parentindex=$1
  let parentPos=`find_node $parentindex`
  let childcount=${nodes[$parentPos]} # childcount is first index of a node struct

  # Jump directly to start of parent node
  echo " >" looking for parent at index $parentindex which was found at $parentPos 1>&2

  let i=1
  while [ $i -le $childcount ] # seq 1 $childcount
  do
    let childPos=i+parentPos
    echo x $i at $childPos x 1>&2
    echo ${nodes[$childPos]} # yeild return 
    let i++
  done
}

function shift() {
  echo " > shift $1" 1>&2
  let pos=$1            # pure shell array index
  # -- Assertions -- #
  [ $pos -le 0 ] && echo "cannot shift count location" 1>&2 && exit 13
  # --            -- #
  let indexstart=1
  effectedNodes=()
  firstEffectedNodeIndex=
  for i in `seq 0 $((nodes[0] - 1))`
  do
    if [ $(( nodes[i + 1] )) -ge $pos ] 
    then
      let nodes[$((i+1))]++ # incrementing node index to reflect shift in referenced values location
    fi
  done

  let nodearraystart=${nodes[0]+1} 
  let i=${#nodes[@]}    # count
  let im1=i-1           # last index
  while [ $i -gt $pos ] # seq $lastindex -1 $1
  do
    let nodes[$i]=${nodes[$im1]} # x[n] = x[n-1]
    let i=im1   # == i--
    let im1=i-1 # == im1--
  done
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

