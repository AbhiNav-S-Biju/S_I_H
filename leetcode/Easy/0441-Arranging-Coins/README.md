# Arranging Coins

**Difficulty:** Easy  
**Topics:** Math, Binary Search  
**LeetCode URL:** [Arranging Coins](https://leetcode.com/problems/arranging-coins/)

## Problem Description

<p>You have <code>n</code> coins and you want to build a staircase with these coins. The staircase consists of <code>k</code> rows where the <code>i<sup>th</sup></code> row has exactly <code>i</code> coins. The last row of the staircase <strong>may be</strong> incomplete.</p>

<p>Given the integer <code>n</code>, return <em>the number of <strong>complete rows</strong> of the staircase you will build</em>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>
<img alt="" src="https://assets.leetcode.com/uploads/2021/04/09/arrangecoins1-grid.jpg" style="width: 253px; height: 253px;" />
<pre>
<strong>Input:</strong> n = 5
<strong>Output:</strong> 2
<strong>Explanation:</strong> Because the 3<sup>rd</sup> row is incomplete, we return 2.
</pre>

<p><strong class="example">Example 2:</strong></p>
<img alt="" src="https://assets.leetcode.com/uploads/2021/04/09/arrangecoins2-grid.jpg" style="width: 333px; height: 333px;" />
<pre>
<strong>Input:</strong> n = 8
<strong>Output:</strong> 3
<strong>Explanation:</strong> Because the 4<sup>th</sup> row is incomplete, we return 3.
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= n &lt;= 2<sup>31</sup> - 1</code></li>
</ul>

## Solution

```java
// LeetCode Problem: Arranging Coins
// Link: https://leetcode.com/problems/arranging-coins/
// Difficulty: Easy
// Language: java

class Solution {
    public int arrangeCoins(int n) {
        long low = 1;
        long high = n;

        while (low <= high) {
            long mid = low + (high - low) / 2;

            long sum = mid * (mid + 1) / 2;

            if (sum == n) {
                return (int) mid;
            } 
            else if (sum < n) {
                low = mid + 1;
            } 
            else {
                high = mid - 1;
            }
        }

        return (int) high;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
