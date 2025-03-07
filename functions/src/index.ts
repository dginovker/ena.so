import { onRequest } from "firebase-functions/v2/https";
import * as cors from "cors";

const corsHandler = cors({ origin: true });

export const checkString = onRequest((request, response) => {
    corsHandler(request, response, () => {
        const inputString = request.query.string as string;

        if (inputString === "abcdefg") {
            response.send(true);
        } else {
            response.send(false);
        }
    });
});
