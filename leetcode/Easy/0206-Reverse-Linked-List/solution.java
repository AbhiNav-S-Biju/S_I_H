// LeetCode Problem: Reverse Linked List
// Link: https://leetcode.com/problems/reverse-linked-list/
// Difficulty: Easy
// Language: java

class Solution {
    public ListNode reverseList(ListNode head) {
        ListNode prev = null;
        ListNode curr = head;

        while (curr != null) {
            ListNode next = curr.next;
            curr.next = prev;
            prev = curr;
            curr = next;
        }
        return prev;
    }
}