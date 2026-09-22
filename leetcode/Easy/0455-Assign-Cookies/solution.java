// LeetCode Problem: Assign Cookies
// Link: https://leetcode.com/problems/assign-cookies/
// Difficulty: Easy
// Language: java

class Solution {
    public int findContentChildren(int[] g, int[] s) {
        int child = g.length;
        int cookie=s.length;
        Arrays.sort(g);
        Arrays.sort(s);
        int count=0;
        for(int i=0;i<child;i++){
            for(int j=0;j<cookie;j++){
                if(g[i]<=s[j]){
                    count++;
                    s[j]=-1;
                    break;
                }
            }
        }
        return count;
    }
}