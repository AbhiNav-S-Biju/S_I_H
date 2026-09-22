# Move Zeroes

**Difficulty:** Easy  
**Topics:** Array, Two Pointers  
**LeetCode URL:** [Move Zeroes](https://leetcode.com/problems/move-zeroes/)

## Problem Description

<p>Given an integer array <code>nums</code>, move all <code>0</code>&#39;s to the end of it while maintaining the relative order of the non-zero elements.</p>

<p><strong>Note</strong> that you must do this in-place without making a copy of the array.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>
<pre><strong>Input:</strong> nums = [0,1,0,3,12]
<strong>Output:</strong> [1,3,12,0,0]
</pre><p><strong class="example">Example 2:</strong></p>
<pre><strong>Input:</strong> nums = [0]
<strong>Output:</strong> [0]
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= nums.length &lt;= 10<sup>4</sup></code></li>
	<li><code>-2<sup>31</sup> &lt;= nums[i] &lt;= 2<sup>31</sup> - 1</code></li>
</ul>

<p>&nbsp;</p>
<strong>Follow up:</strong> Could you minimize the total number of operations done?

## Solution

```java
// LeetCode Problem: Move Zeroes
// Link: https://leetcode.com/problems/move-zeroes/
// Difficulty: Easy
// Language: java

class Solution {
    public void moveZeroes(int[] nums) {
        int i = 0;
        for(int j:nums){
            if(j != 0){
                nums[i] = j;
                i++;
            }
        }
        while(i<nums.length){
            nums[i] = 0;
            i++;
        }
        System.out.println(nums);
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
