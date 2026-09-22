# Spiral Matrix

**Difficulty:** Medium  
**Topics:** Array, Matrix, Simulation  
**LeetCode URL:** [Spiral Matrix](https://leetcode.com/problems/spiral-matrix/)

## Problem Description

<p>Given an <code>m x n</code> <code>matrix</code>, return <em>all elements of the</em> <code>matrix</code> <em>in spiral order</em>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>
<img alt="" src="https://assets.leetcode.com/uploads/2020/11/13/spiral1.jpg" style="width: 242px; height: 242px;" />
<pre>
<strong>Input:</strong> matrix = [[1,2,3],[4,5,6],[7,8,9]]
<strong>Output:</strong> [1,2,3,6,9,8,7,4,5]
</pre>

<p><strong class="example">Example 2:</strong></p>
<img alt="" src="https://assets.leetcode.com/uploads/2020/11/13/spiral.jpg" style="width: 322px; height: 242px;" />
<pre>
<strong>Input:</strong> matrix = [[1,2,3,4],[5,6,7,8],[9,10,11,12]]
<strong>Output:</strong> [1,2,3,4,8,12,11,10,9,5,6,7]
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>m == matrix.length</code></li>
	<li><code>n == matrix[i].length</code></li>
	<li><code>1 &lt;= m, n &lt;= 10</code></li>
	<li><code>-100 &lt;= matrix[i][j] &lt;= 100</code></li>
</ul>

## Solution

```java
// LeetCode Problem: Spiral Matrix
// Link: https://leetcode.com/problems/spiral-matrix/
// Difficulty: Medium
// Language: java

class Solution {
    public List<Integer> spiralOrder(int[][] matrix) {
        List<Integer> a=new ArrayList<>();
        int c1=0,c2=matrix[0].length-1;
        int r1=0,r2=matrix.length-1;
        int c=0;
        while(c<matrix.length*matrix[0].length){
            
            for(int i=c1;i<=c2&&c<matrix.length*matrix[0].length;i++){
            a.add(matrix[r1][i]);
            c++;
        }
        r1++;
        for(int i=r1;i<=r2&&c<matrix.length*matrix[0].length;i++){
            a.add(matrix[i][c2]);
            c++;
        }
        c2--;
        for(int i=c2;i>=c1&&c<matrix.length*matrix[0].length;i--){
            a.add(matrix[r2][i]);
            c++;
        }
        r2--;
        for(int i=r2;i>=r1&&c<matrix.length*matrix[0].length;i--){
            a.add(matrix[i][c1]);
            c++;
        }
        c1++;}
        return a;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
