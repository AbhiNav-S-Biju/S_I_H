// LeetCode Problem: Baseball Game
// Link: https://leetcode.com/problems/baseball-game/
// Difficulty: Easy
// Language: java

class Solution {
    public int calPoints(String[] operations) {
        Stack<Integer> st = new Stack<>();
        for(String ch: operations){
            if(ch.equals("+")){
                int num1 = st.pop();
                int num2 = st.peek();
                st.push(num1);
                st.push(num1+num2);
            }
            else if(ch.equals("D")){
                int num1 = st.peek();
                st.push(num1*2);
            }
            else if(ch.equals("C")){
                st.pop();
            }
            else{
                st.push(Integer.parseInt(ch));
            }
        }
        int sum = 0;
        while(!st.isEmpty()){
            int num1 = st.pop();
            sum += num1;
        }
        return sum;
    }
}