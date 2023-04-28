/**
 * A simple node.js API for use in an AWS cloud project
 *
 * Code modified from @jacksonyuan-yt 
 * https://github.com/jacksonyuan-yt/dynamodb-crud-api-gateway
 */
import {
    DynamoDBClient,
    GetItemCommand,
    PutItemCommand,
    DeleteItemCommand,
    ScanCommand,
    UpdateItemCommand,
} from "@aws-sdk/client-dynamodb";
import { marshall, unmarshall } from "@aws-sdk/util-dynamodb";

const db = new DynamoDBClient({});
const responseTemplate = {
    "statusCode": 200,
    "isBase64Encoded": false,
    "headers": {
        "content-type": "application/json"
    },
    "body": "{}"
}

/**
 * Get a post by postId.
 * @param event - The event object containing the postId.
 * @returns The response object with the post data.
 */
const getPost = async (event: any) => {
    const response = Object.assign({}, responseTemplate);

    try {
        const params = {
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: marshall({ postId: event.pathParameters.postId }),
        };
        const { Item } = await db.send(new GetItemCommand(params));

        console.log({ Item });
        response.body = JSON.stringify({
            message: "Successfully retrieved post.",
            data: Item ? unmarshall(Item) : {},
            rawData: Item,
        });
    } catch (e) {
        console.error(e);
        response.statusCode = 500;
        response.body = JSON.stringify({
            message: "Failed to get post.",
            errorMsg: e.message,
            errorStack: e.stack,
        });
    }

    return response;
};
  
/**
 * Create a new post.
 * @param event - The event object containing the post data.
 * @returns The response object with the creation result.
 */
const createPost = async (event: any) => {
    const response = Object.assign({}, responseTemplate);

    try {
        const body = JSON.parse(event.body);
        const params = {
            TableName: process.env.DYNAMODB_TABLE_NAME,
            Item: marshall(body || {}),
        };
        const createResult = await db.send(new PutItemCommand(params));
        response.statusCode = 201;
        response.body = JSON.stringify({
            message: "Successfully created post.",
            data: body,
            createResult,
        });
    } catch (e) {
        console.error(e);
        response.statusCode = 500;
        response.body = JSON.stringify({
            message: "Failed to create post.",
            errorMsg: e.message,
            errorStack: e.stack,
        });
    }

    return response;
};
  
/**
 * Update a post by postId.
 * @param event - The event object containing the postId and the new post data.
 * @returns The response object with the update result.
 */
const updatePost = async (event: any) => {
    const response = Object.assign({}, responseTemplate);
  
    try {
      const body = JSON.parse(event.body);
      const objKeys = Object.keys(body);
      const params = {
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: marshall({ postId: event.pathParameters.postId }),
        UpdateExpression: `SET ${objKeys
          .map((_, index) => `#key${index} = :value${index}`)
          .join(", ")}`,
        ExpressionAttributeNames: objKeys.reduce(
          (acc, key, index) => ({
            ...acc,
            [`#key${index}`]: key,
          }),
          {}
        ),
        ExpressionAttributeValues: marshall(
          objKeys.reduce(
            (acc, key, index) => ({
              ...acc,
              [`:value${index}`]: body[key],
            }),
            {}
          )
        ),
      };
      const updateResult = await db.send(new UpdateItemCommand(params));
  
      response.body = JSON.stringify({
        message: "Successfully updated post.",
        updateResult,
      });
    } catch (e) {
      console.error(e);
      response.statusCode = 500;
      response.body = JSON.stringify({
        message: "Failed to update post.",
        errorMsg: e.message,
        errorStack: e.stack,
      });
    }
  
    return response;
};

/**
 * Delete a post by postId.
 * @param event - The event object containing the postId.
 * @returns The response object with the deletion result.
 */
const deletePost = async (event: any) => {
    const response = Object.assign({}, responseTemplate);
  
    try {
      const params = {
        TableName: process.env.DYNAMODB_TABLE_NAME,
        Key: marshall({ postId: event.pathParameters.postId }),
      };
      const deleteResult = await db.send(new DeleteItemCommand(params));
  
      response.body = JSON.stringify({
        message: "Successfully deleted post.",
        deleteResult,
      });
    } catch (e) {
      console.error(e);
      response.statusCode = 500;
      response.body = JSON.stringify({
        message: "Failed to delete post.",
        errorMsg: e.message,
        errorStack: e.stack,
      });
    }
  
    return response;
};

/**
 * Get all posts.
 * @returns The response object with all the posts.
 */
const getAllPosts = async () => {
    const response = Object.assign({}, responseTemplate);
  
    try {
      const { Items } = await db.send(
        new ScanCommand({ TableName: process.env.DYNAMODB_TABLE_NAME })
      );
  
      response.body = JSON.stringify({
        message: "Successfully retrieved all posts.",
        data: Items.map((item) => unmarshall(item)),
        Items,
      });
    } catch (e) {
      console.error(e);
      response.statusCode = 500;
      response.body = JSON.stringify({
        message: "Failed to retrieve posts.",
        errorMsg: e.message,
        errorStack: e.stack,
      });
    }
  
    return response;
};

module.exports = {
    getPost,
    createPost,
    updatePost,
    deletePost,
    getAllPosts,
};