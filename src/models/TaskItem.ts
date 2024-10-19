export interface blockedSlotOfTask {
  start: string;
  end: string;
}

export type TCompletedTaskTiming = { goalid: string; start: string; deadline: string };
export interface TaskItem {
  id: string;
  goalId: string;
  title: string;
  blockedSlots: blockedSlotOfTask[];
  completedTodayTimings: TCompletedTaskTiming[]; //  to store timings of the tasks that are completed today
}
