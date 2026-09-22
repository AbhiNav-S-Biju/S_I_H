# First Unique Character in a String

**Difficulty:** Easy  
**Topics:** Hash Table, String, Queue, Counting  
**LeetCode URL:** [First Unique Character in a String](https://leetcode.com/problems/first-unique-character-in-a-string/)

## Problem Description

<p>Given a string <code>s</code>, find the <strong>first</strong> non-repeating character in it and return its index. If it <strong>does not</strong> exist, return <code>-1</code>.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>

<div class="example-block">
<p><strong>Input:</strong> <span class="example-io">s = &quot;leetcode&quot;</span></p>

<p><strong>Output:</strong> <span class="example-io">0</span></p>

<p><strong>Explanation:</strong></p>

<p>The character <code>&#39;l&#39;</code> at index 0 is the first character that does not occur at any other index.</p>
</div>

<p><strong class="example">Example 2:</strong></p>

<div class="example-block">
<p><strong>Input:</strong> <span class="example-io">s = &quot;loveleetcode&quot;</span></p>

<p><strong>Output:</strong> <span class="example-io">2</span></p>
</div>

<p><strong class="example">Example 3:</strong></p>

<div class="example-block">
<p><strong>Input:</strong> <span class="example-io">s = &quot;aabb&quot;</span></p>

<p><strong>Output:</strong> <span class="example-io">-1</span></p>
</div>

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= s.length &lt;= 10<sup>5</sup></code></li>
	<li><code>s</code> consists of only lowercase English letters.</li>
</ul>

## Constraints



## Solution

```java
// LeetCode Problem: First Unique Character in a String
// Link: https://leetcode.com/problems/first-unique-character-in-a-string/
// Difficulty: Easy
// Language: java

class Solution {
    public int firstUniqChar(String s) {
        s = s.toLowerCase();
        int a[] = new int[26];
        for(int i = 0; i<s.length(); i++){
            char c = s.charAt(i);
            a[c-'a']++;
        }
        for(int i = 0; i<s.length();i++){
            char c = s.charAt(i);
            if(a[c-'a']==1){
                return i;
            }
        }
        return -1;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
