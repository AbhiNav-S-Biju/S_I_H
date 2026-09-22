# Spiral Matrix II

**Difficulty:** Medium  
**Topics:** Array, Matrix, Simulation  
**LeetCode URL:** [Spiral Matrix II](https://leetcode.com/problems/spiral-matrix-ii/)

## Problem Description

<p>Given a positive integer <code>n</code>, generate an <code>n x n</code> <code>matrix</code> filled with elements from <code>1</code> to <code>n<sup>2</sup></code> in spiral order.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>
<img alt="" src="https://assets.leetcode.com/uploads/2020/11/13/spiraln.jpg" style="width: 242px; height: 242px;" />
<pre>
<strong>Input:</strong> n = 3
<strong>Output:</strong> [[1,2,3],[8,9,4],[7,6,5]]
</pre>

<p><strong class="example">Example 2:</strong></p>

<pre>
<strong>Input:</strong> n = 1
<strong>Output:</strong> [[1]]
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= n &lt;= 20</code></li>
</ul>

## Solution

```java
// LeetCode Problem: Spiral Matrix II
// Link: https://leetcode.com/problems/spiral-matrix-ii/
// Difficulty: Medium
// Language: java

class Solution {
    public int[][] generateMatrix(int n) {
        int top = 0;
        int left = 0;
        int bottom = n-1;
        int right = n-1;
        int num = 1;
        int[][] mat = new int[n][n];
        while(top<=bottom){
            for(int i = left; i<=right;i++){
                mat[top][i] = num++;
            }
            top++;
            for(int i = top; i<=bottom; i++){
                mat[i][right] = num++;
            }
            right--;
            if(top<=bottom){
                for(int i = right; i>=left;i--){
                    mat[bottom][i] = num++;
                }
                bottom--;
            }
            if(left<=right){
                for(int i = bottom; i>=top; i--){
                    mat[i][left] = num++;
                }
                left++;
            }
        }
        return mat;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
