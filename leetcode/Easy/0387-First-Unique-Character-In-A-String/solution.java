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