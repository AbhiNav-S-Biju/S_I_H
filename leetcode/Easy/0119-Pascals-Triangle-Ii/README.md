# Pascal's Triangle II

**Difficulty:** Easy  
**Topics:** Array, Dynamic Programming  
**LeetCode URL:** [Pascal's Triangle II](https://leetcode.com/problems/pascals-triangle-ii/)

## Problem Description

<p>Given an integer <code>rowIndex</code>, return the <code>rowIndex<sup>th</sup></code> (<strong>0-indexed</strong>) row of the <strong>Pascal&#39;s triangle</strong>.</p>

<p>In <strong>Pascal&#39;s triangle</strong>, each number is the sum of the two numbers directly above it as shown:</p>
<img alt="" src="https://upload.wikimedia.org/wikipedia/commons/0/0d/PascalTriangleAnimated2.gif" style="height:240px; width:260px" />
<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>
<pre><strong>Input:</strong> rowIndex = 3
<strong>Output:</strong> [1,3,3,1]
</pre><p><strong class="example">Example 2:</strong></p>
<pre><strong>Input:</strong> rowIndex = 0
<strong>Output:</strong> [1]
</pre><p><strong class="example">Example 3:</strong></p>
<pre><strong>Input:</strong> rowIndex = 1
<strong>Output:</strong> [1,1]
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>0 &lt;= rowIndex &lt;= 33</code></li>
</ul>

<p>&nbsp;</p>
<p><strong>Follow up:</strong> Could you optimize your algorithm to use only <code>O(rowIndex)</code> extra space?</p>

## Solution

```java
// LeetCode Problem: Pascal's Triangle II
// Link: https://leetcode.com/problems/pascals-triangle-ii/
// Difficulty: Easy
// Language: java

class Solution {
    public List<Integer> getRow(int rowIndex) {
       List<List<Integer>> result = new ArrayList<>();
        for(int i = 0; i<=rowIndex;i++){
            List<Integer> row = new ArrayList<>();
            for(int j = 0; j<=i; j++){
                if(j == 0||j==i){
                    row.add(1);
                }
                else{
                    int left = result.get(i-1).get(j-1);
                    int right = result.get(i-1).get(j);
                    row.add(left+right);
                }
            }
            result.add(row);
        }  
        return result.get(rowIndex); 
    }
}

```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
