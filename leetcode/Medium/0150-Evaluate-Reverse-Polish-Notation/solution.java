// LeetCode Problem: Evaluate Reverse Polish Notation
// Link: https://leetcode.com/problems/evaluate-reverse-polish-notation/
// Difficulty: Medium
// Language: java

class Solution {
    public int evalRPN(String[] tokens) {
        Stack<Integer> st = new Stack<>();
        for(String s:tokens){
            if(s.equals("+")){
                int num1 = st.pop();
                int num2 = st.pop();
                st.push(num1+num2);
            }
            else if(s.equals("-")){
                int num1 = st.pop();
                int num2 = st.pop();
                st.push(num2-num1);
            }
            else if(s.equals("*")){
                int num1 = st.pop();
                int num2 = st.pop();
                st.push(num1*num2);
            }
            else if(s.equals("/")){
                int num1 = st.pop();
                int num2 = st.pop();
                st.push((int)num2/num1);
            }
            else{
                st.push(Integer.parseInt(s));
            }
        }
        return st.pop();
    }
}