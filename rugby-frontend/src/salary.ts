// Monetary values are cents; the ledger retains its weekly payment cadence.
export const monthlySalary=(weeklyCents:number)=>Math.round(weeklyCents*52/12);
export const weeklySalary=(monthlyCents:number)=>Math.round(monthlyCents*12/52);
