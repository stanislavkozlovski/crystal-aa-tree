class Object
    # Hack to preserve the .as() calls
    def as(_)
        self
    end
end

class AANode
    attr_accessor :value, :parent, :left, :right, :level

    def initialize(value:, level:, left: nil, right: nil, parent: nil)
        @value = value
        @level = level
        @parent = parent
        @left = left
        @right = right
    end
end

class AATree
    def initialize(root)
        @root = root
        @count = 1
    end
end

class AANode
    #
    # Returns the grandparent of the node
    #
    def grandparent
        if @parent.nil?
            nil
        else
            @parent.as(AANode).parent
        end
    end

    #
    # Returns a boolean indicating if the given aaNode is the right grandchild
    # 1								5
    #  \								 \
    #   2								  7
    #    \							 /
    #     3 							6
    #  In the above example, 3 is a right grandchild of 1.
    #  6 is not a right grandchild of 5
    #
    def is_right_grandchild?(grandparent)
        (!grandparent.right.nil?) && (!grandparent.right.as(AANode).right.nil?) && grandparent.right.as(AANode).right == self
    end
end

class AATree
    def initialize(root)
        @root = root
        @count = 1
    end

    def contains?(value)
        if @root.nil?
            raise Exception.new("Tree is empty!")
        else
            _contains?(value, @root.as(AANode))
        end
    end

    protected def _contains?(value, node)
        if node.value > value
            if node.left.nil?
                false
            else
                _contains?(value, node.left.as(AANode))
            end
        elsif node.value < value
            if node.right.nil?
                false
            else
                _contains?(value, node.right.as(AANode))
            end
        else
            true
        end
    end

    #
    # Adds a value into the tree
    #
    def add(value)
        if @root.nil?
            @root = AANode.new(value: value, level: 1)
        else
            self._add(value, @root.as(AANode))
        end
        @count += 1
    end

    #
    # Removes a value from the tree
    #
    def remove(value)
        if @root.nil?
            raise Exception.new("There is nothing to remove!")
        elsif @count == 1
            @root = nil
            @count = 0
            return
        end

        _remove(value, @root)
        @count -= 1
    end

    #
    # Removes a value from the tree
    #
    protected def _remove(value, node)
        if node.nil?
            raise Exception.new("Value #{value} is not in the tree!")
        end

        if node.value != value
            # recurse downwards until we find the right node
            if node.value > value
                _remove(value, node.left)
            else
                _remove(value, node.right)
            end
        else
            # We're at the correct node, remove it
            if node.right.nil? && node.left.nil?
                # We're at a leaf, simply remove it
                parent = node.parent.as(AANode)
                if parent.left == node
                    parent.left =  nil
                else
                    parent.right = nil
                end
            elsif node.left.nil?
                # there is a right node, get the successor
                successor = node.right.as(AANode)
                until successor.left.nil?
                    successor = successor.left.as(AANode) 
                end

                # Swap both nodes
                node.value = successor.value
                succ_parent = successor.parent.as(AANode)
                if succ_parent.right == successor
                    succ_parent.right = nil
                else
                    succ_parent.left = nil
                end
            else
                # there is a left node, get the predecessor
                predecessor = node.left.as(AANode)
                until predecessor.right.nil?
                    predecessor = predecessor.right.as(AANode) 
                end

                # Swap both nodes
                node.value = predecessor.value
                pred_parent = predecessor.parent.as(AANode)
                if pred_parent.right == predecessor
                    pred_parent.right = nil
                else
                    pred_parent.left = nil
                end
            end
        end

        # The node is removed, now fix the levels

        # left node should be exactly one level less
        left_level_is_wrong = (!node.left.nil? && node.left.as(AANode).level < node.level - 1) || (node.left.nil? && node.level > 1)  # if we don't have a left node, our level should be 1

        # right node should be exactly one less or equal
        right_level_is_wrong = (!node.right.nil? && node.right.as(AANode).level < node.level - 1) || (node.right.nil? && node.level > 1)  # if we don't have a right node, our level should be 1

        # If there is no break in the levels there is no need  to do rebalance operations
        return unless (left_level_is_wrong || right_level_is_wrong)

        node.level -= 1
        if (!node.right.nil? && node.right.as(AANode).level > node.level)
            # right node had the equal level and is now bigger after our decrease, so we reset its level
            node.right.as(AANode).level = node.level
        end

        check_skew(node, false)
        unless node.right.nil?
            check_skew(node.right.as(AANode), false)
        end
        unless node.left.nil?
            check_skew(node.left.as(AANode), false)
        end

        if (!node.right.nil? && !node.right.as(AANode).left.nil?)
            check_skew(node.right.as(AANode).left.as(AANode), false)
        end
        if (!node.right.nil? && !node.right.as(AANode).right.nil? && !node.right.as(AANode).right.as(AANode).left.nil?)
            check_skew(node.right.as(AANode).right.as(AANode).left.as(AANode), false)
        end

        check_split(node)

        # if we do a split, we need to keep track of the right-right leaf so that we can check it for a split as well
        if (!node.right.nil? && !node.right.as(AANode).right.nil?)
            right_right_leaf = node.right.as(AANode).right.as(AANode)

            check_split(right_right_leaf)

            if (!right_right_leaf.right.nil? && !right_right_leaf.right.as(AANode).right.nil?)
                check_split(right_right_leaf.right.as(AANode).right.as(AANode))
            end

            unless node.right.nil?
                check_split(node.right.as(AANode))
            end
        end
    end

    #
    # The internal add function, which traverses the trees nodes until it lands at the correct node,
    # left/right of which the new node should be inserted.
    # Backtracing from the recursion, we check if we should perform a split or skew operation*/
    #
    protected def _add(value, node)
        if value < node.value
            # go left
            if node.left.nil?
                # new left AANode
                new_node = AANode.new(value: value, level: 1, parent: node)
                node.left = new_node
                check_skew(new_node, true)
            else
                _add(value, node.left.as(AANode))
            end
        elsif value > node.value
            # go right
            if node.right.nil?
                new_node = AANode.new(value: value, level: 1, parent: node)
                node.right = new_node

                # we've added a right node, check for a split
                check_split(new_node)
            else
                _add(value, node.right.as(AANode))
            end
        else
            raise Exception.new("Equal elements are unsupported!")
        end

        # backtracing through the path, check for skews and then for splits
        check_skew(node, true)
        check_split(node)
    end

    #
    # Performs a split operation, given the three needed nodes
    # 11(R)                  	12
    #   \			    	   /  \
    #    12(P)   ===>		 11    13
    #     \
    #      13(C)
    #      P becomes the new root, where any leaf that was left of P is now to the right of R
    #      i.e if 12 had a left child 11.5, 11.5 should become the right child of the new 11
    #
    
    def split(grandparent, parent)
        # fixes grandparent's link
        grand_grandparent = grandparent.parent
        unless grand_grandparent.nil?
            if grand_grandparent.left == grandparent
                grand_grandparent.left = parent
            else
                grand_grandparent.right = parent
            end
        end 

        if grandparent == @root
            # we now have a new root
            @root = parent
        end

        parent.parent = grand_grandparent  # R parent is now some upwards node
        grandparent.parent = parent  # R parent is now P
        grandparent.right = parent.left
        unless parent.left.nil?
            parent.left.as(AANode).parent = grandparent
        end
        parent.left = grandparent
        parent.level += 1
    end

    # Given a node, check if a Split operation should be performed, by checking the node's grandparent level
	# The node we're given would be the downmost one in the split operation */
    def check_split(node)
        grandparent = node.grandparent
        if (!grandparent.nil?) && node.is_right_grandchild?(grandparent) && grandparent.level <= node.level
            split(grandparent, node.parent.as(AANode))
        end
    end

    #
    # Performs a skew operation, given the two needed nodes
    #     12(A) 1                11(B)1
    #     /          ===>          \
    #   11(B) 1                   12(A)1
    #
    def skew(parent, leaf)
        grandparent = parent.parent
        unless grandparent.nil?
            if grandparent.value < parent.value
                # new GP right
                grandparent.right = leaf
            else
                grandparent.left = leaf
            end
        else
            @root = leaf
        end

        leaf.parent = grandparent
        old_right = leaf.right
        leaf.right = parent
        parent.left = old_right
        unless old_right.nil?
            old_right.parent = parent
        end
        parent.parent = leaf
    end

    #  Given a node, check is a Skew operation should be performed by checking if its a left child
    #     and if its level is bigger or equal to his parent's
    # param: checkForSplit - a boolean indicating if we want to split if it's ok to split after the skew
    #         We generally don't want to do that in deletions, as in the example on the TestFunctionalTestTreeRemoval function
    #         where we remove 1 from the tree
    #
    def check_skew(node, check_for_split)
        parent = node.parent
        if (!parent.nil?) && parent.left == node && parent.level <= node.level
            skew(parent, node)
            # check for split; Parent would now be the middle element
            if (!parent.right.nil?) && check_for_split
                if parent.right.as(AANode).is_right_grandchild?(node) && node.level <= parent.right.as(AANode).level
                    split(node, parent)
                end
            end
        end
    end
end

root = AANode.new(value: 100, level: 1)
tree = AATree.new(root)

100.times do |num|
    raise Exception.new("Tree should not contain #{num}") if tree.contains?(num)
    tree.add(num)
    raise Exception.new("Tree should contain #{num}") unless tree.contains?(num)
end

100.times do |num|
    raise Exception.new("Tree should contain #{num}") unless tree.contains?(num)
    tree.remove(num)
    raise Exception.new("Tree should not contain #{num}") if tree.contains?(num)
end
