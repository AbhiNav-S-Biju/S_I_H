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