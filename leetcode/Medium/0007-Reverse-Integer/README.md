# Reverse Integer

**Difficulty:** Medium  
**Topics:** Math  
**LeetCode URL:** [Reverse Integer](https://leetcode.com/problems/reverse-integer/)

## Problem Description

<p>Given a signed 32-bit integer <code>x</code>, return <code>x</code><em> with its digits reversed</em>. If reversing <code>x</code> causes the value to go outside the signed 32-bit integer range <code>[-2<sup>31</sup>, 2<sup>31</sup> - 1]</code>, then return <code>0</code>.</p>

<p><strong>Assume the environment does not allow you to store 64-bit integers (signed or unsigned).</strong></p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>

<pre>
<strong>Input:</strong> x = 123
<strong>Output:</strong> 321
</pre>

<p><strong class="example">Example 2:</strong></p>

<pre>
<strong>Input:</strong> x = -123
<strong>Output:</strong> -321
</pre>

<p><strong class="example">Example 3:</strong></p>

<pre>
<strong>Input:</strong> x = 120
<strong>Output:</strong> 21
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>-2<sup>31</sup> &lt;= x &lt;= 2<sup>31</sup> - 1</code></li>
</ul>

## Solution

```java
// LeetCode Problem: Reverse Integer
// Link: https://leetcode.com/problems/reverse-integer/
// Difficulty: Medium
// Language: java

class Solution {
public int reverse(int x) {
        int c=x, rev = 0, rem;
        while(c!=0){
            rem = c%10;
            if(rev < (Integer.MIN_VALUE/10) || rev > (Integer.MAX_VALUE/10)){
                return 0;
            }
            rev = (rev*10) + rem;
            c = c/10;
        }
        return rev;
    
    }
};

```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
