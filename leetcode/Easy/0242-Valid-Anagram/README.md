# Valid Anagram

**Difficulty:** Easy  
**Topics:** Hash Table, String, Sorting  
**LeetCode URL:** [Valid Anagram](https://leetcode.com/problems/valid-anagram/)

## Problem Description

<p>Given two strings <code>s</code> and <code>t</code>, return <code>true</code> if <code>t</code> is an <span data-keyword="anagram">anagram</span> of <code>s</code>, and <code>false</code> otherwise.</p>

<p>&nbsp;</p>

## Examples

<p><strong class="example">Example 1:</strong></p>

<div class="example-block">
<p><strong>Input:</strong> <span class="example-io">s = &quot;anagram&quot;, t = &quot;nagaram&quot;</span></p>

<p><strong>Output:</strong> <span class="example-io">true</span></p>
</div>

<p><strong class="example">Example 2:</strong></p>

<div class="example-block">
<p><strong>Input:</strong> <span class="example-io">s = &quot;rat&quot;, t = &quot;car&quot;</span></p>

<p><strong>Output:</strong> <span class="example-io">false</span></p>
</div>

<p>&nbsp;</p>
<p><strong>Constraints:</strong></p>

<ul>
	<li><code>1 &lt;= s.length, t.length &lt;= 5 * 10<sup>4</sup></code></li>
	<li><code>s</code> and <code>t</code> consist of lowercase English letters.</li>
</ul>

<p>&nbsp;</p>
<p><strong>Follow up:</strong> What if the inputs contain Unicode characters? How would you adapt your solution to such a case?</p>

## Constraints



## Solution

```java
// LeetCode Problem: Valid Anagram
// Link: https://leetcode.com/problems/valid-anagram/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isAnagram(String s, String t) {
        if(s.length()!= t.length()){
            return false;
        }
        HashMap <Character, Integer> m = new HashMap<>();
        for(char c: s.toCharArray())
            m.put(c,m.getOrDefault(c,0)+1);
        for(char c:t.toCharArray()){
            if(m.containsKey(c)){
                m.put(c,m.get(c)-1);
                if(m.get(c)==0) m.remove(c);
            }
        }
        if(m.isEmpty()) return true;
        return false;
    }
}
```

---
<div align="center">

**🔄 Synced with [CommitSync](https://www.google.com/search?q=CommitSync+extension)**

*Automatically organized and synced by CommitSync.*

</div>
