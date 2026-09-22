# Happy Number

**Difficulty:** Easy  
**Topics:** Hash Table, Math, Two Pointers, Floyd's Cycle Finding Algorithm  
**LeetCode URL:** [Happy Number](https://leetcode.com/problems/happy-number/)

## Problem Description

<p>Write an algorithm to determine if a number <code>n</code> is happy.</p>

<p>A <strong>happy number</strong> is a number defined by the following process:</p>

<ul>
	<li>Starting with any positive integer, replace the number by the sum of the squares of its digits.</li>
	<li>Repeat the process until the number equals 1 (where it will stay), or it <strong>loops endlessly in a cycle</strong> which does not include 1.</li>
	<li>Those numbers for which this process <strong>ends in 1</strong> are happy.</li>
</ul>

<p>Return <code>true</code> <em>if</em> <code>n</code> <em>is a happy number, and</em> <code>false</code> <em>if not</em>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>

<pre>
<strong>Input:</strong> n = 19
<strong>Output:</strong> true
<strong>Explanation:</strong>
1<sup>2</sup> + 9<sup>2</sup> = 82
8<sup>2</sup> + 2<sup>2</sup> = 68
6<sup>2</sup> + 8<sup>2</sup> = 100
1<sup>2</sup> + 0<sup>2</sup> + 0<sup>2</sup> = 1
</pre>

<p><strong class="example">Example 2:</strong></p>

<pre>
<strong>Input:</strong> n = 2
<strong>Output:</strong> false
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= n &lt;= 2<sup>31</sup> - 1</code></li>
</ul>

## Solution

```java
// LeetCode Problem: Happy Number
// Link: https://leetcode.com/problems/happy-number/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isHappy(int n) {
        
        HashSet<Integer> s = new HashSet<>();
        while(n!=1 && !s.contains(n)){
            s.add(n);
            n = sumofSq(n);
        }
        if(n == 1)return true;
        else return false;
    }
    int sumofSq(int n){
        int rem, sum = 0;
        while(n!= 0){
            rem = n%10;
            sum = sum + (rem*rem);
            n = n/10;
        }
        return sum;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
