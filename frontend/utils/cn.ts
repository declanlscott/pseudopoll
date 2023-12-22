import clsx from "clsx";
import { twMerge } from "tailwind-merge";

import type { ClassValue } from "clsx";

export default (...inputs: ClassValue[]) => twMerge(clsx(inputs));
