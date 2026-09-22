// LeetCode Problem: Isomorphic Strings
// Link: https://leetcode.com/problems/isomorphic-strings/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isIsomorphic(String s, String t) {
        if (s.length() != t.length()) return false;
        
        HashMap<Character, Character> m = new HashMap<>();
        HashSet<Character> set = new HashSet<>();
        
        for (int i = 0; i < s.length(); i++) {
            char c1 = s.charAt(i);
            char c2 = t.charAt(i);
            
            // If the character from 's' is already in the map
            if (m.containsKey(c1)) {
                // It must map to the current character in 't'
                if (m.get(c1) != c2) {
                    return false;
                }
            } else {
                // If 'c1' is new, 'c2' must not have been mapped to by another character
                if (set.contains(c2)) {
                    return false;
                }
                
                // Add the new mapping and mark 'c2' as used
                m.put(c1, c2);
                set.add(c2);
            }
        }
        return true;
    }
}