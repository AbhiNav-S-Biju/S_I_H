# Intersection of Two Arrays II

**Difficulty:** Easy  
**Topics:** Array, Hash Table, Two Pointers, Binary Search, Sorting  
**LeetCode URL:** [Intersection of Two Arrays II](https://leetcode.com/problems/intersection-of-two-arrays-ii/)

## Problem Description

<p>Given two integer arrays <code>nums1</code> and <code>nums2</code>, return <em>an array of their intersection</em>. Each element in the result must appear as many times as it shows in both arrays and you may return the result in <strong>any order</strong>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>

<pre>
<strong>Input:</strong> nums1 = [1,2,2,1], nums2 = [2,2]
<strong>Output:</strong> [2,2]
</pre>

<p><strong class="example">Example 2:</strong></p>

<pre>
<strong>Input:</strong> nums1 = [4,9,5], nums2 = [9,4,9,8,4]
<strong>Output:</strong> [4,9]
<strong>Explanation:</strong> [9,4] is also accepted.
</pre>

## Constraints

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= nums1.length, nums2.length &lt;= 1000</code></li>
	<li><code>0 &lt;= nums1[i], nums2[i] &lt;= 1000</code></li>
</ul>

<p>&nbsp;</p>
<p><strong>Follow up:</strong></p>

<ul>
	<li>What if the given array is already sorted? How would you optimize your algorithm?</li>
	<li>What if <code>nums1</code>&#39;s size is small compared to <code>nums2</code>&#39;s size? Which algorithm is better?</li>
	<li>What if elements of <code>nums2</code> are stored on disk, and the memory is limited such that you cannot load all elements into the memory at once?</li>
</ul>

## Solution

```java
// LeetCode Problem: Intersection of Two Arrays II
// Link: https://leetcode.com/problems/intersection-of-two-arrays-ii/
// Difficulty: Easy
// Language: java

class Solution {
    public int[] intersect(int[] a1, int[] a2) {
        HashMap<Integer, Integer> m = new HashMap<>();
        for(int e: a1)
            m.put(e,m.getOrDefault(e,0)+1);
        List<Integer> ans = new ArrayList<>();
        for(int e:a2){
            if(m.containsKey(e)&&m.get(e)>0){
                ans.add(e);
                m.put(e,m.get(e)-1);
            }
        }
        int[] res = new int[ans.size()];
        for(int i = 0; i<ans.size(); i++){
            res[i] = ans.get(i);
        }
        return res;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
