# Power of Four

**Difficulty:** Easy  
**Topics:** Math, Bit Manipulation, Recursion  
**LeetCode URL:** [Power of Four](https://leetcode.com/problems/power-of-four/)

## Problem Description

<p>Given an integer <code>n</code>, return <em><code>true</code> if it is a power of four. Otherwise, return <code>false</code></em>.</p>

<p>An integer <code>n</code> is a power of four, if there exists an integer <code>x</code> such that <code>n == 4<sup>x</sup></code>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>
<pre><strong>Input:</strong> n = 16
<strong>Output:</strong> true
</pre><p><strong class="example">Example 2:</strong></p>
<pre><strong>Input:</strong> n = 5
<strong>Output:</strong> false
</pre><p><strong class="example">Example 3:</strong></p>
<pre><strong>Input:</strong> n = 1
<strong>Output:</strong> true
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>-2<sup>31</sup> &lt;= n &lt;= 2<sup>31</sup> - 1</code></li>
</ul>

<p>&nbsp;</p>
<strong>Follow up:</strong> Could you solve it without loops/recursion?

## Solution

```java
// LeetCode Problem: Power of Four
// Link: https://leetcode.com/problems/power-of-four/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isPowerOfFour(int n) {
         if (n <= 0) {
            return false;
        }
        while(n%4 == 0){
            n = n/4;
        }
        if(n == 1){
            return true;
        }
        return false;
    }
}

```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
