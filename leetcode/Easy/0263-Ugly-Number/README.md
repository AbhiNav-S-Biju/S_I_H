# Ugly Number

**Difficulty:** Easy  
**Topics:** Math  
**LeetCode URL:** [Ugly Number](https://leetcode.com/problems/ugly-number/)

## Problem Description

<p>An <strong>ugly number</strong> is a <em>positive</em> integer which does not have a prime factor other than 2, 3, and 5.</p>

<p>Given an integer <code>n</code>, return <code>true</code> <em>if</em> <code>n</code> <em>is an <strong>ugly number</strong></em>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>

<pre>
<strong>Input:</strong> n = 6
<strong>Output:</strong> true
<strong>Explanation:</strong> 6 = 2 &times; 3
</pre>

<p><strong class="example">Example 2:</strong></p>

<pre>
<strong>Input:</strong> n = 1
<strong>Output:</strong> true
<strong>Explanation:</strong> 1 has no prime factors.
</pre>

<p><strong class="example">Example 3:</strong></p>

<pre>
<strong>Input:</strong> n = 14
<strong>Output:</strong> false
<strong>Explanation:</strong> 14 is not ugly since it includes the prime factor 7.
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>-2<sup>31</sup> &lt;= n &lt;= 2<sup>31</sup> - 1</code></li>
</ul>

## Solution

```java
// LeetCode Problem: Ugly Number
// Link: https://leetcode.com/problems/ugly-number/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isUgly(int n) {
        if(n <= 0) return false;
        while(n%2 == 0){
                n = n/2;
        }
        while(n%3 == 0){
                n = n/3;
        }
        while(n%5 == 0){
                n = n/5;
        }
        if(n == 1) return true;
        return false;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
