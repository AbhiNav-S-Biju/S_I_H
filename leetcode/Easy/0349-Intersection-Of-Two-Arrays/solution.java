// LeetCode Problem: Intersection of Two Arrays
// Link: https://leetcode.com/problems/intersection-of-two-arrays/
// Difficulty: Easy
// Language: java

class Solution {
    public int[] intersection(int[] a1, int[] a2) {
        HashSet<Integer> s = new HashSet<>();
        HashSet<Integer> ans = new HashSet<>();
        for(int e: a1)
            s.add(e);
        for(int n:a2){
              if(s.contains(n))
                ans.add(n);

        }
         int[] res = new int[ans.size()];
         int i = 0;
         for(int n:ans){
            res[i] = n;
            i++;
         } 
         return res;
    }
}